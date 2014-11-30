#!/usr/bin/make -f

fontpath=/usr/share/fonts/truetype/malayalam
font=Chilanka

default: compile
all: compile webfonts

compile:
	@echo "Generating ${font}.ttf"
	@fontforge -lang=ff -c "Open('${font}.sfd'); Generate('${font}.ttf')";

webfonts:compile
	@echo "Generating webfonts";
	@sfntly -w ${font}.ttf ${font}.woff;
	@sfntly -e -x ${font}.ttf ${font}.eot;
	@[ -x `which woff2_compress` ] && woff2_compress ${font}.ttf;

install: compile
	@install -D -m 0644 ${font}.ttf ${DESTDIR}/${fontpath}/$${font}.ttf;
