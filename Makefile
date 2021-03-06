################################################################################
#	Makefile for tnote.sh
#
#	Technically, no 'making' occurs, since it's just a shell script, but
#	let us not quibble over trivialities such as these.
################################################################################
PREFIX=/usr
SRC=src
SRCFILE=tnote.sh
DESTFILE=tnote
DOC=doc
MANPATH=$(PREFIX)/share/man/man1
MANFILE=tnote.1.gz
DATAPATH=$(PREFIX)/share/tnote


install:
	$(info )
	$(info *** INSTALL ***)
	@install -D -m 0755 $(SRC)/$(SRCFILE) $(PREFIX)/bin/$(DESTFILE)
	@mkdir -vp $(DATAPATH)
	@install -v -D -m 0644 LICENSE $(DATAPATH)/LICENSE
	@install -v -D -m 0644 README $(DATAPATH)/README
	@install -D -m 0644 $(DOC)/$(MANFILE) $(MANPATH)/$(MANFILE)

uninstall:
	$(info )
	$(info *** UNINSTALL ***)
	rm -f $(PREFIX)/bin/$(DESTFILE)
	rm -rf $(DATAPATH)
	rm -f $(MANPATH)/$(MANFILE)
