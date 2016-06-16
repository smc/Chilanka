#!/usr/bin/make -f

fontpath=/usr/share/fonts/truetype/malayalam
fonts=Chilanka-Regular
feature=features/features.fea
PY=python2.7
buildscript=tools/build.py
version=1.2
default: compile
all: compile webfonts test
compile:
	@for font in `echo ${fonts}`;do \
		$(PY) $(buildscript) -t ttf -i $$font.sfd -f $(feature) -v $(version);\
	done;

webfonts:woff woff2
woff: compile
	@rm -rf *.woff
	@for font in `echo ${fonts}`;do \
		$(PY) $(buildscript) -t woff -i $$font.ttf;\
	done;
woff2: compile
	@rm -rf *.woff2
	@for font in `echo ${fonts}`;do \
		$(PY) $(buildscript) -t woff2 -i $$font.ttf;\
	done;

install: compile
	@for font in `echo ${fonts}`;do \
		install -D -m 0644 $${font}.otf ${DESTDIR}/${fontpath}/$${font}.ttf;\
	done;

test: compile
# Test the fonts
	@for font in `echo ${fonts}`; do \
		echo "Testing font $${font}";\
		hb-view $${font}.ttf --font-size 14 --margin 100 --line-space 1.5 --foreground=333333  --text-file tests/tests.txt --output-file tests/$${font}.pdf;\
	done;
clean:
	@rm -rf *.otf *.ttf *.woff *.woff2 *.sfd-*