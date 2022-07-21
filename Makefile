# variables
RMD := $(wildcard *.Rmd)

HANDOUTS := $(RMD:%.Rmd=handout_files/%.pdf)
NOTES := $(RMD:%.Rmd=pdfnotes/%.pdf)
PDF := $(RMD:%.Rmd=pdf/%.pdf)
PPTX := $(RMD:%.Rmd=sourcedir/%.pptx)
SOURCE := $(RMD:%.Rmd=sourcedir/%.md)

cruft = knit_files tex tex_notes

# targets
.PHONY: all
all: $(PDF)

.PHONY: notes
notes: $(NOTES)

.PHONY: handouts
handouts: $(HANDOUTS)

.PHONY: source
source: $(SOURCE) $(PPTX)

clean:
	$(RM) -rf $(cruft)

# handouts pipeline (no animations)
$(HANDOUTS) : handout_files/%.pdf : tex/%.tex | handout_files
	$(eval TMP := $(shell mktemp -d))
	sed  "s/documentclass\[/documentclass[handout,/g" $< > $(TMP)/source.tex
	xelatex	-output-directory=$(TMP) $(TMP)/source.tex \
	&& xelatex	-output-directory=$(TMP) $(TMP)/source.tex \
	&& xelatex	-output-directory=$(TMP) $(TMP)/source.tex
	cp $(TMP)/source.pdf $@
	rm -r $(TMP)

# Notes pipeline
$(NOTES) : pdfnotes/%.pdf : tex_notes/%.tex | pdfnotes
	$(eval TMP := $(shell mktemp -d))
	cp $< $(TMP)/source.tex
	xelatex	-output-directory=$(TMP) $(TMP)/source.tex \
	&& xelatex	-output-directory=$(TMP) $(TMP)/source.tex \
	&& xelatex	-output-directory=$(TMP) $(TMP)/source.tex
	cp $(TMP)/source.pdf $@
	rm -r $(TMP)

tex_notes/%.tex : knit_files/%.knit.md style/header.tex style/body.tex style/notes.tex style/title_slide_template.eps | tex_notes
		/usr/bin/env pandoc \
		+RTS -K512m \
		-RTS $< \
		-o $@ \
		--to beamer-smart \
		--from markdown+autolink_bare_uris+ascii_identifiers+tex_math_single_backslash-implicit_figures+smart \
		--output $@ \
		--highlight-style tango \
		--self-contained \
		--variable=mathspec \
		--include-in-header style/notes.tex \
		--include-before-body style/body.tex

# Full PDF pipeline
$(PDF) : pdf/%.pdf : tex/%.tex | pdf
	$(eval TMP := $(shell mktemp -d))
	cp $< $(TMP)/source.tex
	xelatex	-output-directory=$(TMP) $(TMP)/source.tex \
	&& xelatex	-output-directory=$(TMP) $(TMP)/source.tex \
	&& xelatex	-output-directory=$(TMP) $(TMP)/source.tex
	cp $(TMP)/source.pdf $@
	rm -r $(TMP)


tex/%.tex : knit_files/%.knit.md style/header.tex style/body.tex style/title_slide_template.eps | tex
		/usr/bin/env pandoc \
		+RTS -K512m \
		-RTS $< \
		--to beamer-smart \
		--from markdown+autolink_bare_uris+ascii_identifiers+tex_math_single_backslash-implicit_figures+smart \
		--output $@ \
		--highlight-style tango \
		--self-contained \
		--variable=mathspec \
		--include-in-header style/header.tex \
		--include-before-body style/body.tex

# PPTX slides and clean markdown
$(SOURCE) : sourcedir/%.md : knit_files/%.knit.md | sourcedir
		/usr/bin/env pandoc \
		+RTS -K512m \
		-RTS $^ \
		--to markdown \
		--from markdown+autolink_bare_uris+ascii_identifiers+tex_math_single_backslash-implicit_figures \
		--output $@ \
		--highlight-style tango \
		--self-contained \
		--lua-filter=style/notefilter.lua


$(PPTX) : sourcedir/%.pptx : knit_files/%.knit.md | sourcedir
		/usr/bin/env pandoc \
		+RTS -K512m \
		-RTS $^ \
		--to pptx \
		--from markdown+autolink_bare_uris+ascii_identifiers+tex_math_single_backslash-implicit_figures \
		--output $@ \
		--highlight-style tango \
		--self-contained \
		--lua-filter=style/notefilter.lua


# knit the RMD
knit_files/%.knit.md : knit_files/%.Rmd | knit_files
	R -e "rmarkdown::render('$^',clean=FALSE,run_pandoc=FALSE, knit_root_dir='..')"

knit_files/%.Rmd : %.Rmd  style/beamer.yaml style/header.tex style/r_setup.Rmd | knit_files
	cat style/beamer.yaml style/r_setup.Rmd $< > $@

# working directories
sourcedir:
	mkdir $@

pdf:
	mkdir $@

knit_files:
	mkdir $@

tex:
	mkdir $@

tex_notes:
	mkdir $@

pdfnotes:
	mkdir $@

handout_files:
	mkdir $@
