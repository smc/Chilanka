#!/usr/bin/make -f

fontpath=/usr/share/fonts/truetype/malayalam
font=Chilanka

default: all
all: compile test webfonts

compile:
	@echo "Generating ${font}.ttf"
	@./generate.pe ${font}.sfd;

webfonts:
	@echo "Generating webfonts"
	@sfntly -w ${font}.ttf ${font}.woff;
	@sfntly -e -x ${font}.ttf ${font}.eot;

test: compile
# Test the fonts
	@echo "Testing font ${font}";
	@hb-view ${font}.ttf --debug --text-file tests/tests.txt --output-file tests/${font}.pdf;
