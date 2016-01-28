#!/bin/bash
################################################################################
#   tnote.sh        |   version 0.2    |       GPL v3      |   2016-01-28
#   Florian Poeck   |   fidel@yafp.de
################################################################################


###########################################################
# CONFIG AND STUFF
###########################################################

## Define some formatting variables for output
bold=$(tput bold)
normal=$(tput sgr0)
underline=$(tput smul)

# colors
black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
lime_yellow=$(tput setaf 190)
powder_blue=$(tput setaf 153)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)



###########################################################
# CHECK REQUIREMENTS
###########################################################
function check_requirements
{
    ##  Default 'system' directory for tnote sheets
    if [[ -d "/usr/local/share/tnote" ]]; then
        TNOTE_SYS_DIR=/usr/local/share/tnote
    else
        TNOTE_SYS_DIR=/usr/share/tnote
    fi

    ##  Default tnote viewer program
    if [[ -z $TNOTE_TEXT_VIEWER ]]; then
        TNOTE_TEXT_VIEWER="cat"
    fi

    ##  User directory for tnote notes
    if [[ -z $DEFAULT_TNOTE_DIR ]]; then # if var is empty -> set it
        DEFAULT_TNOTE_DIR="${HOME}/.tnote"
    fi

    ## check if note folder doesnt exists
    if [ ! -d "$DEFAULT_TNOTE_DIR" ]; then
        mkdir "$DEFAULT_TNOTE_DIR"
        printf "Initially created tNote notes folder at: $DEFAULT_TNOTE_DIR\n"
    fi

    ##  note path
    if [[ -z $TNOTEPATH ]]; then
        TNOTEPATH="${DEFAULT_TNOTE_DIR}"
    fi

    ##  Check to make sure that their tnote directory exists.  If it does, great.
    ##  If not, exit and tell them.
    if [ ! -n "$TNOTEPATH" ]; then
        if [ ! -d "$TNOTE_SYS_DIR" ] && [ ! -d "$DEFAULT_TNOTE_DIR" ]; then
            echo "ERROR:  No tNote directory found." 1>&2
            echo -e "\tConsult the help (tnote -h) for more info" 1>&2
            exit 1
        else
            cp -r "$TNOTE_SYS_DIR" "$DEFAULT_TNOTE_DIR"
            TNOTEPATH="$DEFAULT_TNOTE_DIR"
            if [ ! -d "$DEFAULT_TNOTE_DIR" ]; then
                echo "ERROR:  Cannot write to $DEFAULT_TNOTE_DIR" 1>&2
                exit 1
            fi
        fi
    fi
}



###########################################################
# OTHER FUNCTIONS
###########################################################

## Function:     Clears the screen & prints the header
## Arguments:	 none
function display_header
{
    clear
    printf "${underline}${bold}tNote${normal} - $1\n\n"
}


## Function:     Prints a new line
## Arguments:	 
function newLine
{
    printf "\n"
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
    printf "  -l or --list:\t\t\tList all notes with full paths\n"

    printf "${bold}- Create and edit:${normal}\n"
    printf "  -a or --add:\t\t\tCreate a new note\n"
    printf "  -e or --edit:\t\t\tEdit a tnote file using default editor\n"
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
    display_header "Version"
    printf "${bold}tnote.sh${normal} - version 0.1 by Florian Poeck (fidel@yafp.de)\n"
}


## Function:    Helper function to grep content of notes
## Arguments:   1 - Whether to list full paths to files.  0 = don't, 1 = do.
function grepper
{
    ##  For every directory in the TNOTEPATH variable
    for arg in ${@:2}; do
        if [[ $1 -eq 0 ]]; then
            echo -e "${underline}$arg:${normal}"
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
    #elif file -bL "$1" | grep gzip > /dev/null; then
        #gunzip --stdout "$dirName/$fileName" | "$TNOTE_TEXT_VIEWER" >& 1
    fi
    printf "\n"
}


###########################################################
# RUN: CHECK REQUIREMENTS
###########################################################
check_requirements


###########################################################
# CHECK USERINPUT a.k.a PARAMETERS
###########################################################

## Function:	Display help
## Arguments:	-h or --help or none
if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ $# -lt 1 ]; then
	print_help
	exit 0
fi


## Function:	Print version information
## Arguments:	-v or --version
if [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
	print_version
	exit 0
fi


## Functions:	Create or Edit a file
## Arguments:	-e or --edit
##              -a or --add
if [ "$1" = "-e" ] || [ "$1" = "--edit" ] || [ "$1" = "-a" ] || [ "$1" = "--add" ]; then

    if [ "$1" = "-a" ] || [ "$1" = "--add" ]; then
        display_header "Adding a new note"
    else
        display_header "Editing an existing note"
    fi

    # check if a second parameter was supplied
    if [ "$#" -lt 2 ]; then
        echo "${red}ERROR:${normal}  No note title specified" 1>&2
        exit 1
    fi

    # check if more then 2 parameter was supplied -> error
    if [ "$#" -gt 2 ]; then
        echo "${red}ERROR:${normal}  Too many parameters ($#)" 1>&2
        exit 1
    fi

    ##  Find an editor for the user
    if [[ -z $EDITOR ]]; then
        find_editor
    fi

    existing=0
    while read F; do
        ##  Check and see if we get any hits on the 'edit' search
        if [[ -e "${F}/${2}" ]]; then # file/note exits
            if file -b "${F}/${2}" | grep text > /dev/null; then
                let existing=$(( $existing + 1 ))
                filesToEdit+=("${F}/${2}")
            else
                echo "${yellow}WARNING:${normal}  Not a text file:  '${2}'"
            fi
        fi
    done < <(echo "$TNOTEPATH" | sed 's/:/\n/g')

    ##  If we didn't get any hits, create one in default dir
    if [[ $existing -eq 0 ]]; then
        filesToEdit+=("${DEFAULT_TNOTE_DIR}/${2}")
    fi

    ##  Edit 'em
    #"$EDITOR" ${filesToEdit[@]} #org
    "$EDITOR" "$filesToEdit" # modified for blank-support

    exit 0
fi


## Function:	Searching for keywords in title
## Arguments:	-st or --searchtitle
if [[ "$1" = "-st" ]] || [[ "$1" = "--searchtitle" ]] ; then
    display_header "Search by title"

    ##  If they did not supply a keyword, list everything
    if [[ $# -eq 1 ]]; then
        echo "$TNOTEPATH" | sed 's/:/\n/g' | while read DIR; do
            ls -1 "$DIR"
        done
        exit 0
    fi

    ##  Grep for every subject they listed as an arg
    for arg in ${@:2}; do
        echo -e "${underline}$arg:${normal}"

        echo "$TNOTEPATH" | sed 's/:/\n/g' | while read DIR; do
            ls "$DIR" | grep -i "$arg" | while read LINE; do
                echo "    $LINE" | sed 's/.gz//g'
            done
        done
    done
    printf "\n"
    exit 0
fi


## Function:	Search for words inside the files
## Arguments:	-sc or --searchcontent
if [[ "$1" = "-sc" ]] || [[ "$1" = "--searchcontent" ]]; then
    display_header "Search note content"
    ##  If they did not supply a keyword, tell them
    if [[ $# -eq 1 ]]; then
        echo "${red}ERROR:${normal}  Keyword(s) required" 1>&2
        exit 1
    fi
    grepper 0 ${@:2}
    printf "\n"
    exit 0
fi


## Function:    Searching inside note titles and content (everywhere)
## Arguments:   -s or --search
if [[ "$1" = "-s" ]] || [[ "$1" = "--search" ]]; then
    display_header "Search everything (titles and content)"

    ##  If no search-phrase was entered - list everything
    if [[ $# -eq 1 ]]; then
        printf "${bold}Listing all notes due to missing searchphrase:${normal}\n"
        echo "$TNOTEPATH" | sed 's/:/\n/g' | while read DIR; do
            ls -1 "$DIR"
        done
        exit 0
    fi

    ##  Grep for every subject they listed as an arg
    printf "${bold}Searching note titles for:${normal}\n"
    for arg in ${@:2}; do
        echo -e "${underline}$arg:${normal}"

        echo "$TNOTEPATH" | sed 's/:/\n/g' | while read DIR; do
            ls "$DIR" | grep -i "$arg" | while read LINE; do
                echo "    $LINE" | sed 's/.gz//g'
            done
        done
    done


    ## by Content
    printf "\n${bold}Searching notes content for:${normal}\n"
    grepper 0 ${@:2}

    exit 0
fi


## Function:	List all files (with or without full path)
## Arguments:	-l or --list
if [[ "$1" = "-l" ]] || [[ "$1" = "--list" ]]; then
    display_header "List all notes"
    echo "$TNOTEPATH" | sed 's/:/\n/g' | while read DIR; do
        ls "$DIR" | while read LINE; do
            #echo "    ${DIR}/${LINE}"    # full path
            echo "    ${LINE}"            # only note-name
        done
    done
    printf "\n"
    exit 0
fi





#==============================     MAIN    ====================================
<<COMMENT
userinput triggered none of the parameter-cases above
so we can test if his parameter is a note-name or a part of a note-name 
-> if so display the results

note-content is ignored at this point
COMMENT


RESULTS=0
declare RESULTS_ARRAY=()

while read DIR; do
    ##  If we hit an 'exact' match
    if [[ -e "$DIR/$1" ]]; then
        echo -e "$1\n"
        "$TNOTE_TEXT_VIEWER" "$DIR/$1"
        exit 0
    elif [[ -e "$DIR/${1}.gz" ]]; then
        echo -e "$1\n"
        gunzip --stdout "$DIR/${1}.gz" | "$TNOTE_TEXT_VIEWER" >& 1
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
    printf "${red}ERROR:${normal}  No file matching pattern '$1' in $TNOTEPATH\n\n" 1>&2
    exit 1

##  If there is 1 result, display that note
elif [ $RESULTS -eq 1 ]; then
    display_header "Display single note"
    for R in ${RESULTS_ARRAY[@]}; do
        fileName="$(echo "$R" | cut -f1 -d':')"
        dirName="$(echo "$R" | cut -f2 -d':')"

        printf "Note: ${bold}$fileName${normal}\n\n" # output note-name
        view_file "$dirName/$fileName"
    done

##  If there's more than 1, display to the user his/her possibilities
elif [ $RESULTS -gt 1 ]; then
    display_header "Search note by name (>1 results)"
    for arg in ${@:1}; do

        echo "${underline}$arg:${normal}"
        #echo ""

        for R in ${RESULTS_ARRAY[@]}; do
            echo "    $R" | cut -f1 -d':'
        done
    done
fi

#==============================  END MAIN    ===================================

exit 0