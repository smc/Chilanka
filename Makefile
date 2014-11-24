#!/usr/bin/make -f

fontpath=/usr/share/fonts/truetype/malayalam
font=Chilanka

default: all
all: compile test webfonts

compile:
	@echo "Generating ${font}.ttf"
	@fontforge -lang=ff -c "Open('${font}.sfd'); Generate('${font}.ttf')";

webfonts:compile
	@echo "Generating webfonts";
	@sfntly -w ${font}.ttf ${font}.woff;
	@sfntly -e -x ${font}.ttf ${font}.eot;
	@[ -x `which woff2_compress` ] && woff2_compress ${font}.ttf;

test: compile
# Test the fonts
	@echo "Testing font ${font}";
	@hb-view ${font}.ttf --text-file tests/tests.txt --output-file tests/${font}.pdf;
