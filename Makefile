#!/usr/bin/make -f

fontpath=/usr/share/fonts/truetype/malayalam
fonts=Chilanka-Regular
feature=features/features.fea
PY=python2.7
buildscript=tools/build.py
version=1.2
default: compile
all: compile

compile: clean
	@for font in `echo ${fonts}`;do \
		echo "Generating $$font.ttf";\
		$(PY) $(buildscript) $$font.sfd $(feature) $(version);\
	done;

install: compile
	@for font in `echo ${fonts}`;do \
		install -D -m 0644 $${font}.ttf ${DESTDIR}/${fontpath}/$${font}.ttf;\
	done;

test: compile
# Test the fonts
	@for font in `echo ${fonts}`; do \
		echo "Testing font $${font}";\
		hb-view $${font}.ttf --text-file tests/tests.txt --output-file tests/$${font}.pdf;\
	done;
dist:
	@for font in `echo ${fonts}`;do \
		cp $${font}.ttf ttf/$${font}.ttf;\
	done;
clean:
	@rm -rf *.ttf *.sfd-* *.woff* *.eot