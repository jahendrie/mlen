################################################################################
#	Makefile for mlen.sh
#
#	Technically, no 'making' occurs, since it's just a shell script, but
#	let us not quibble over trivialities such as these.
################################################################################
ROOTPATH=
PREFIX=$(ROOTPATH)/usr
SRC=src
SRCFILE=mlen.sh
DESTFILE=mlen
DOC=doc
DATA=data
MANPATH=$(PREFIX)/share/man/man1
DATAPATH=$(PREFIX)/share/mlen

install:
	install -D -g 0 -o 0 -m 0755 $(SRC)/$(SRCFILE) $(PREFIX)/bin/$(DESTFILE)
	install -v -D -g 0 -o 0 -m 0644 LICENSE $(DATAPATH)/LICENSE
	install -v -D -g 0 -o 0 -m 0644 README $(DATAPATH)/README
	install -v -D -g 0 -o 0 -m 0644 README $(DATAPATH)/CHANGES
	install -D -g 0 -o 0 -m 0644 $(DOC)/mlen.1 $(MANPATH)/mlen.1

uninstall:
	rm -f $(PREFIX)/bin/$(DESTFILE)
	rm -f $(DATAPATH)/LICENSE
	rm -f $(DATAPATH)/README
	rm -f $(DATAPATH)/CHANGES
	rmdir $(DATAPATH)
	rm -f $(MANPATH)/mlen.1
