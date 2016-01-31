#!/bin/bash
################################################################################
#   tnote.sh        |   version 0.3    |       GPL v3      |   2016-01-30
#   Florian Poeck   |   https://github.com/yafp/tnote
################################################################################


#===================     CONFIG AND OTHER DEFINITIONS    =======================

appName="tNote"                                 # script name
appVersion="0.3.20160131.01"                    # script version
appDialogHeadline="$appName - (v$appVersion)"

# get size of term-window
width="$(tput cols)"   # number of columns.
height="$(tput lines)" # number of rows.

# calc 90% of those values
width="$(echo "$width*0.9" | bc)"
height="$(echo "$height*0.8" | bc)"
width=${width%.*}
height=${height%.*}


## Define some formatting variables for output
bold=$(tput bold)
normal=$(tput sgr0)
underline=$(tput smul)
nounderline=$(tput rmul)

# Define some colors  for printf output
black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)


#============================     FUNCTIONS    =================================

## Function:     Prints a new line
## Arguments:    amount of new lines (example: newLine 5)
function newLine
{
    loopCycle="0"
    while [ $loopCycle -lt $1 ]
    do
        printf "\n"
        loopCycle=$[$loopCycle+1]
    done
}

## Function:     Clears the screen & prints the header
## Arguments:	 none
function display_header
{
    clear
    printf "${underline}${bold}$appName${normal} - (v$appVersion) - $1"
    newLine 2
}


## Function:     Check all the requirements
## Arguments:	 none
function check_requirements
{
    display_header "Checking requirements"
    ##  Default 'system' directory for notes
    if [[ -d "/usr/local/share/tnote" ]]; then
        TNOTE_SYS_DIR=/usr/local/share/tnote
    else
        TNOTE_SYS_DIR=/usr/share/tnote
    fi

    ##  Default tnote viewer program
    if [[ -z $TNOTE_TEXT_VIEWER ]]; then
        TNOTE_TEXT_VIEWER="cat"

        # check if 'cat' exists
        if hash cat 2>/dev/null; then
            printf "${green}[OK]${normal}\tFound required cat\n"
        else
            printf "${red}ERROR:${normal} cat is missing ... get one.\n"
            exit 1
        fi
    fi

    # Check if 'dialog' exists
    if hash dialog 2>/dev/null; then
        printf "${green}[OK]${normal}\tFound dialog\n"
        dialogExist=1
    else
        printf "${yellow}WARNING:${normal} dialog is missing.\n"
        dialogExist=0
    fi

    ##  User directory for tnote notes
    if [[ -z $DEFAULT_TNOTE_DIR ]]; then # if var is empty -> set it
        DEFAULT_TNOTE_DIR="${HOME}/.tnote"
    fi

    ## check if note folder doesnt exists
    if [ ! -d "$DEFAULT_TNOTE_DIR" ]; then
        mkdir "$DEFAULT_TNOTE_DIR"

        if [[ "$dialogExist" == 1 ]]; then
            dialog --title "Missing $appName folder" --backtitle "$appDialogHeadline" --msgbox "Created $appName folder $DEFAULT_TNOTE_DIR" 5 80
        else
            printf "${green}[OK]${normal}\tCreated $appName folder $DEFAULT_TNOTE_DIR\n"
        fi
    fi

    ##  note path
    if [[ -z $TNOTEPATH ]]; then
        TNOTEPATH="${DEFAULT_TNOTE_DIR}"
    fi

    ##  Check to make sure that their tnote directory exists.  If it does, great.
    ##  If not, exit and tell them.
    if [ ! -n "$TNOTEPATH" ]; then
        if [ ! -d "$TNOTE_SYS_DIR" ] && [ ! -d "$DEFAULT_TNOTE_DIR" ]; then
            printf "${red}ERROR:${normal}  No t$appName directory found.\n" 1>&2
            printf "\tConsult the help (tnote -h) for more info\n" 1>&2
            exit 1
        else
            cp -r "$TNOTE_SYS_DIR" "$DEFAULT_TNOTE_DIR"
            TNOTEPATH="$DEFAULT_TNOTE_DIR"
            if [ ! -d "$DEFAULT_TNOTE_DIR" ]; then
                printf "${red}ERROR:${normal}  Cannot write to $DEFAULT_TNOTE_DIR\n" 1>&2
                exit 1
            fi
        fi
    fi

    printf "\nFinished checking requirements without issues\n"

    # might be nice to display notes - in read-only mode if that makes sense at all
    #dialog --textbox /etc/profile $height $width
    #exit 1
}


## Function:     Detects the default editor of the user
## Arguments:    none
function find_editor
{
    editors=( 'vim' 'vi' 'nano' 'emacs' 'ed' 'ex' 'gedit' 'kate' 'geany' )

    for e in "${editors[@]}"; do
        if which "$e" > /dev/null; then
            export EDITOR="$e"
            return 0
        fi
    done

    printf "${red}ERROR:${normal}  Cannot find an editor.  Use EDITOR environment variable.\n"
    exit 1
}


## Function:     Display user help
## Arguments:    none
function print_help
{
    display_header "Help"

    printf "${bold}Usage:${normal}  tnote [OPTION] FILE\n\n"
    printf "${bold}Options:${normal}\n"

    printf "${bold}- Search:${normal}\n"
    printf "  -s or --search:\t\tSearch for keyword(s) in note titles and content\n"
    printf "  -st or --searchtitle:\t\tSearch for keyword(s) in note titles\n"
    printf "  -sc or --searchcontent:\tSearch for keyword(s) in note content\n"
    printf "  -l or --list:\t\t\tList all notes\n"

    printf "${bold}- Add,edit and delete:${normal}\n"
    printf "  -a or --add:\t\t\tCreate a new note\n"
    printf "  -e or --edit:\t\t\tEdit a note using default editor\n"
    printf "  -d or --delete:\t\tDelete a note\n"

    printf "${bold}- Misc:${normal}\n"
    printf "  -h or --help:\t\t\tThis help screen\n"
    printf "  -v or --version:\t\tDisplay version information\n"

    printf "\n${bold}Examples:${normal}\n"
    printf "  tnote -s foo:\t\t\tFind all notes containing the string 'foo'\n"
    printf "  tnote bar:\t\t\tDisplay note with title 'bar'\n"

    printf "\nBy default, tNote notes are kept in the ~/.tnote directory.\n"
    printf "See the README file for more details.\n"
}


## Function:    Display version information
## Arguments:   none
function print_version
{
    display_header "Version details"
    printf "${bold}tnote.sh${normal} - version $appVersion by Florian Poeck (https://github.com/yafp/tnote)\n"
}


## Function:    Helper function to grep content of notes
## Arguments:   1 - Whether to list full paths to files.  0 = don't, 1 = do.
function grepper
{
    ##  For every directory in the TNOTEPATH variable
    for arg in ${@:2}; do
        if [[ $1 -eq 0 ]]; then
            printf "[$arg]\n"
        fi

        echo "$TNOTEPATH" | sed 's/:/\n/g' | while read DIR; do

            ##  Change to directory with tnote notes
            cd "$DIR"

            ##  Grep through all of the tnote notes
            ls | while read LINE; do
                grep -i "$arg" "$LINE" &> /dev/null
                if [[ $? -eq 0 ]]; then
                    if [[ $1 -eq 0 ]]; then
                        echo "    $LINE"
                    else
                        echo "$PWD/$LINE"
                    fi
                fi
            done

            ##  Go back to previous directory
            cd - &> /dev/null
        done
    done
}


## Function:    loads and displays the content of a single note
## Arguments:   1 (The full file name, including path)
function view_file
{
    ##  Text files
    if file -bL "$1" | grep text > /dev/null; then
        "$TNOTE_TEXT_VIEWER" "$1"
    fi
    newLine 1
}


## Function:    lists all notes
## Arguments:   none
function list_all_notes
{
    echo "$TNOTEPATH" | sed 's/:/\n/g' | while read DIR; do
        ls "$DIR" | while read LINE; do
            #echo "    ${DIR}/${LINE}"          # full path
            printf "    ${LINE}\n"              # only note-name
        done

        # count notes
        noteCount=$(ls -1 "$DIR" --file-type | grep -v '/$' | wc -l)
        printf "\n    ${underline}Total notes:${normal} ${bold}$noteCount${normal}"
    done
    newLine 2
}

## Function:    delete a note
## Arguments:
function delete_file()
{
	local f="$1"
	local m="$0: file $f failed to delete."
	if [ -f $f ]
	then
		/bin/rm $FILE && m="$0: $f file deleted."
	else
		m="$0: $f is not a file."
	fi
	dialog --title "Remove file" --backtitle "$appDialogHeadline" --clear --msgbox "$m" 10 50
    clear
}

#=======================     CHECK REQUIREMENTS    =============================
check_requirements


#===================     CHECK FOR MISSING PARAMETER    ========================
if [ $# -lt 1 ]; then
	print_help
	exit 0
fi


#==============================     MAIN    ====================================
# react on user input

case $1 in
# Display version
"-v" | "--version")
    print_version
    exit 0
    ;;

# Display help
"-h" | "--help")
    print_help
    exit 0
    ;;

# List all notes
"-l" | "--list")
    display_header "List all notes in ${underline}$DEFAULT_TNOTE_DIR${normal}"
    list_all_notes
    exit 0
    ;;

# Search anywhere
"-s" | "--search")
    display_header "Search anywhere (titles and content)"

    ##  If no search-phrase was entered - list everything
    if [[ $# -eq 1 ]]; then
        display_header "List all notes (due to missing searchphrase)"
        list_all_notes
        exit 0
    fi

    ##  Grep for every subject/title they listed as an arg
    printf "${bold}Titles:${normal}\n"
    for arg in ${@:2}; do
        printf "[$arg]\n"

        echo "$TNOTEPATH" | sed 's/:/\n/g' | while read DIR; do
            ls "$DIR" | grep -i "$arg" | while read LINE; do
                echo "    $LINE" | sed 's/.gz//g'
            done
        done
    done

    ## Search the content
    printf "\n${bold}Content:${normal}\n"
    grepper 0 ${@:2}
    exit 0
    ;;

# Search only title
"-st" | "--searchtitle")
    display_header "Search note titles"

    ##  If they did not supply a keyword, list everything
    if [[ $# -eq 1 ]]; then
        echo "$TNOTEPATH" | sed 's/:/\n/g' | while read DIR; do
            ls -1 "$DIR"
        done
        exit 0
    fi

    ##  Grep for every subject they listed as an arg
    for arg in ${@:2}; do
        printf "[$arg]\n"

        echo "$TNOTEPATH" | sed 's/:/\n/g' | while read DIR; do
            ls "$DIR" | grep -i "$arg" | while read LINE; do
                echo "    $LINE" | sed 's/.gz//g'
            done
        done
    done
    newLine 1
    exit 0
    ;;

# Search only content
"-sc" | "--searchcontent")
    display_header "Search note content"
    ##  If they did not supply a keyword, tell them
    if [[ $# -eq 1 ]]; then
        printf "${red}ERROR:${normal}  Keyword(s) required\n" 1>&2
        exit 1
    fi
    grepper 0 ${@:2}
    newLine 1
    exit 0
    ;;

# Edit or add
"-e" | "--edit" | "-a" | "--add")
    if [ "$1" = "-a" ] || [ "$1" = "--add" ]; then
        display_header "Adding a new note"
    else
        display_header "Editing an existing note"
    fi

    # check if a second parameter was supplied
    if [ "$#" -lt 2 ]; then
        if [ "$1" = "-a" ] || [ "$1" = "--add" ]; then # user wants to add a new note but has not entered a fileName - make it interactive instead
            if [[ "$dialogExist" == 1 ]]; then
                user_input=$(\
                    dialog --title "Missing note name" \
                    --backtitle "$appDialogHeadline"\
                    --inputbox "Enter name for new note:" 8 $width \
                    3>&1 1>&2 2>&3 3>&- \
                )
                clear

                if [[ "$user_input" == "" ]]; then # user entered no note name in interactive dialog
                    printf "${red}ERROR:${normal}  No note title specified\n" 1>&2
                    exit 1
                fi
            fi

        else # its edit mode
            printf "${red}ERROR:${normal}  No note title specified\n" 1>&2
            exit 1
        fi
    else # second parm was entered
        user_input=$2
    fi

    # check if more then 2 parameter was supplied -> error
    if [ "$#" -gt 2 ]; then
        printf "${red}ERROR:${normal}  Too many parameters ($#)\n" 1>&2
        exit 1
    fi

    ##  Find an editor for the user
    if [[ -z $EDITOR ]]; then
        find_editor
    fi

    existing=0
    while read F; do
        ##  Check and see if we get any hits on the 'edit' search
        if [[ -e "${F}/${user_input}" ]]; then # file/note exits
            if file -b "${F}/${user_input}" | grep text > /dev/null; then
                let existing=$(( $existing + 1 ))
                filesToEdit+=("${F}/${user_input}")
            else
                printf "${yellow}WARNING:${normal}  Not a text file:  '${user_input}'\n"
            fi
        fi
    done < <(echo "$TNOTEPATH" | sed 's/:/\n/g')

    ##  If we didn't get any hits, create one in default dir
    if [[ $existing -eq 0 ]]; then
        filesToEdit+=("${DEFAULT_TNOTE_DIR}/${user_input}")
    fi

    ##  Edit 'em
    #"$EDITOR" ${filesToEdit[@]} #org
    "$EDITOR" "$filesToEdit" # modified for blank-support

    exit 0
    ;;

# Rename a note
"-r" | "--rename")
    display_header "Renaming a note"
    dialog --title "Rename" --backtitle "$appDialogHeadline" --yesno "Do you really want to rename?" 6 25
    # 0 = yes
    # 1 = no
    response=$?
    case $response in
        0) echo "File deleted.";;
        1) echo "File not deleted.";;
        255) echo "[ESC] key pressed.";;
    esac
    exit 0
    ;;


# Delete a note
    "-d" | "--delete")
    FILE=$(dialog --title "Delete a file" --stdout --title "Please choose a file to delete" --backtitle "$appDialogHeadline" --fselect $DEFAULT_TNOTE_DIR/ 14 48)
    clear
    #echo "${FILE} file chosen."

    # delete file
    [ ! -z $FILE ] && delete_file "$FILE"
    exit 0
    ;;

*)  # Any other unexpected user input - try to search note by title
    RESULTS=0
    declare RESULTS_ARRAY=()

    while read DIR; do

        ##  If we hit an 'exact' match (user entered complete note title)
        if [[ -e "$DIR/$1" ]]; then
            display_header "Note: ${bold}$1${normal}"   # display head for single note
            "$TNOTE_TEXT_VIEWER" "$DIR/$1"              # display note content
            exit 0
        fi

        ##   grab the number of 'hits' given by the user's query
        DIR_RESULTS=$(ls "$DIR" | grep -i "$1" | wc -l)

        if [[ $DIR_RESULTS -gt 0 ]]; then
            while read R; do
                RESULTS_ARRAY+=("${R}:${DIR}")
            done < <(ls "$DIR" | grep -i "$1")
        fi

        let RESULTS=$(( $RESULTS + $DIR_RESULTS ))

    done < <(echo "$TNOTEPATH" | sed 's/:/\n/g')

    ##  If there are no results, inform the user and let the program quit
    if [ $RESULTS -eq 0 ]; then
        display_header "Search note by name (0 results)"
        printf "[$1]\n"   # show searchphrase
        printf "    No file matching pattern '$1' in $TNOTEPATH\n\n" 1>&2
        exit 1

    ##  If there is 1 result, display that note
    elif [ $RESULTS -eq 1 ]; then
        for R in ${RESULTS_ARRAY[@]}; do
            fileName="$(echo "$R" | cut -f1 -d':')"
            dirName="$(echo "$R" | cut -f2 -d':')"

            display_header "Note: ${bold}$fileName${normal}"
            view_file "$dirName/$fileName"
        done

    ##  If there's more than 1, display to the user his/her possibilities
    elif [ $RESULTS -gt 1 ]; then
        display_header "Search note by name (>1 results)"
        for arg in ${@:1}; do
            echo "[$arg]"   # show searchphrase

            for R in ${RESULTS_ARRAY[@]}; do # show results
                echo "    $R" | cut -f1 -d':'
            done
        done
    fi
    exit 0
    ;;
esac
#==============================  END MAIN    ===================================
exit 0
