#!/usr/bin/make -f

fontpath=/usr/share/fonts/truetype/malayalam
font=Kaippada

version = 6.0

default: compile
all: compile test

compile:
# generate ttf files from sfd files
	./generate.pe ${font}.sfd;


test: compile
# Test the fonts
	echo "Testing font ${font}";\
	hb-view ${font}.ttf --debug --text-file tests/tests.txt --output-file tests/${font}.pdf;