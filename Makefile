#!/usr/bin/make -f

fontpath=/usr/share/fonts/truetype/malayalam
fonts=Chilanka-Regular
feature=features/features.fea
PY=python2.7
buildscript=tools/build.py
version=1.3
outdir=build
default: ttf
all: clean ttf webfonts test
.PHONY: ttf
ttf:
	@for font in `echo ${fonts}`;do \
		$(PY) $(buildscript) -t ttf -i $$font.sfd -f $(feature) -v $(version);\
	done;

webfonts:woff woff2
woff: ttf
	@rm -rf *.woff
	@for font in `echo ${fonts}`;do \
		$(PY) $(buildscript) -t woff -i $(outdir)/$$font.ttf;\
	done;
woff2: ttf
	@rm -rf *.woff2
	@for font in `echo ${fonts}`;do \
		$(PY) $(buildscript) -t woff2 -i $(outdir)/$$font.ttf;\
	done;

install: ttf
	@for font in `echo ${fonts}`;do \
		install -D -m 0644 $(outdir)/$${font}.ttf ${DESTDIR}/${fontpath}/$${font}.ttf;\
	done;

ifeq ($(shell ls -l $(outdir)/*.ttf 2>/dev/null | wc -l),0)
test: ttf run-test
else
test: run-test
endif

run-test:
	@for font in `echo ${fonts}`; do \
		echo "Testing font $${font}";\
		hb-view $(outdir)/$${font}.ttf --font-size 14 --margin 100 --line-space 1.5 --foreground=333333  --text-file tests/tests.txt --output-file tests/$${font}.pdf;\
	done;
clean:
	@rm -rf *.otf *.ttf *.woff *.woff2 *.sfd-* tests/*.pdf $(outdir)
