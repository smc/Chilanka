#!/usr/bin/make -f

NAME=Chilanka
FONTS=Regular
INSTALLPATH=/usr/share/fonts/opentype/malayalam
PY=python3
version=`cat VERSION`
TOOLDIR=tools
SRCDIR=sources
tests=tests
BLDDIR=build
default: otf
all: clean lint otf ttf webfonts test
OTF=$(FONTS:%=$(BLDDIR)/$(NAME)-%.otf)
TTF=$(FONTS:%=$(BLDDIR)/$(NAME)-%.ttf)
WOFF2=$(FONTS:%=$(BLDDIR)/$(NAME)-%.woff2)
PDFS=$(FONTS:%=$(BLDDIR)/$(NAME)-%-ligatures.pdf)   \
	$(FONTS:%=$(BLDDIR)/$(NAME)-%-content.pdf)      \
	$(FONTS:%=$(BLDDIR)/$(NAME)-%-table.pdf)

$(BLDDIR)/%.otf: $(SRCDIR)/%.ufo
	@echo "  BUILD    $(@F)"
	@fontmake --validate-ufo --verbose=WARNING -o otf --flatten-components --output-dir $(BLDDIR) -u $<

$(BLDDIR)/%.ttf: $(SRCDIR)/%.ufo
	@echo "  BUILD    $(@F)"
	@fontmake --verbose=WARNING -o ttf --flatten-components --output-dir $(BLDDIR) -u $<

$(BLDDIR)/%.woff2: $(BLDDIR)/%.otf
	@echo "WEBFONT    $(@F)"
	@fonttools ttLib.woff2 compress  $<

$(BLDDIR)/%-table.pdf: $(BLDDIR)/%.ttf
	@echo "   TEST    $(@F)"
	@fntsample --font-file $< --output-file $(BLDDIR)/$(@F)        \
		--style="header-font: Noto Sans Bold 12"                   \
		--style="font-name-font: Noto Serif Bold 12"               \
		--style="table-numbers-font: Noto Sans 10"                 \
		--style="cell-numbers-font:Noto Sans Mono 8"

$(BLDDIR)/%-ligatures.pdf: $(BLDDIR)/%.ttf
	@echo "   TEST    $(@F)"
	@hb-view $< --font-size 14 --margin 100 --line-space 1.5 \
		--foreground=333333 --text-file $(tests)/ligatures.txt \
		--output-file $(BLDDIR)/$(@F);

$(BLDDIR)/%-content.pdf: $(BLDDIR)/%.ttf
	@echo "   TEST    $(@F)"
	@hb-view $< --font-size 14 --margin 100 --line-space 1.5 \
		--foreground=333333 --text-file $(tests)/content.txt \
		--output-file $(BLDDIR)/$(@F);

ttf: $(TTF)
otf: $(OTF)
webfonts: $(WOFF2)
lint: ufolint
ufo: glyphs ufonormalizer lint

ufolint: $(SRCDIR)/*.ufo
	$@ $^
ufonormalizer: $(SRCDIR)/*.ufo
	@for variant in $^;do \
		ufonormalizer -m $$variant;\
	done;
install: otf
	@mkdir -p ${DESTDIR}${INSTALLPATH}
	install -D -m 0644 $(BLDDIR)/*.otf ${DESTDIR}${INSTALLPATH}/

test: ttf otf $(PDFS)
	fontbakery check-ufo-sources $(SRCDIR)/*.ufo
	fontbakery check-googlefonts --full-lists --config fontbakery.yaml --html tests/fontbakery-report.html --ghmarkdown tests/fontbakery-report.md $(BLDDIR)/*.ttf
	# fontbakery check-fontval $(BLDDIR)/*.ttf <- enable when https://github.com/microsoft/Font-Validator/issues/62 fixed
	fontbakery check-opentype $(BLDDIR)/*.otf

clean:
	@rm -rf $(BLDDIR)
