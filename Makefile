RMD := $(wildcard *.Rmd)
TMP := $(RMD:%.Rmd=tmpdir/%.Rmd)
MD := $(RMD:%.Rmd=tmpdir/%.knit.md)
TEXTMP := $(RMD:%.Rmd=tmpdir/%.tex)
NOTETMP := $(RMD:%.Rmd=notetmp/%.tex)
NOTEPDFTMP := $(RMD:%.Rmd=notetmp/%.pdf)
PDFTMP := $(RMD:%.Rmd=tmpdir/%.pdf)
PDF := $(RMD:%.Rmd=pdf/%.pdf)
TEX := $(RMD:%.Rmd=tex/%.tex)
NOTES := $(RMD:%.Rmd=pdfnotes/%.pdf)
SOURCE := $(RMD:%.Rmd=sourcedir/%.md)
PPTX := $(RMD:%.Rmd=sourcedir/%.pptx)

.PHONY: all
all: $(PDF) $(TEX)

.PHONY: notes
notes: $(NOTES)

.PHONY: source
source: $(SOURCE) $(PPTX)

cruft = tmpdir notetmp

clean:
	$(RM) -rf $(cruft)

$(TEX) : tex/%.tex : tmpdir/%.tex | tex
	cp $^ $@

$(PDF) : pdf/%.pdf : tmpdir/%.pdf | pdf
	cp $^ $@

$(NOTES) : pdfnotes/%.pdf : notetmp/%.pdf | pdfnotes
	cp $^ $@


$(PDFTMP) : tmpdir/%.pdf : tmpdir/%.tex | tmpdir
	xelatex -output-directory=tmpdir $^
	xelatex -output-directory=tmpdir $^
	xelatex -output-directory=tmpdir $^


$(NOTEPDFTMP) : notetmp/%.pdf : notetmp/%.tex | notetmp
	xelatex -output-directory=notetmp $^
	xelatex -output-directory=notetmp $^
	xelatex -output-directory=notetmp $^


$(NOTETMP) : notetmp/%.tex : tmpdir/%.knit.md | style/header.tex style/body.tex style/notes.tex notetmp
		/usr/bin/env pandoc \
		+RTS -K512m \
		-RTS $^ \
		-o $@ \
		--to beamer-smart \
		--from markdown+autolink_bare_uris+ascii_identifiers+tex_math_single_backslash-implicit_figures+smart \
		--output $@ \
		--highlight-style tango \
		--self-contained \
		--variable=mathspec \
		--include-in-header style/notes.tex \
		--include-before-body style/body.tex


$(TEXTMP) : tmpdir/%.tex : tmpdir/%.knit.md | style/header.tex style/body.tex tmpdir
		/usr/bin/env pandoc \
		+RTS -K512m \
		-RTS $^ \
		--to beamer-smart \
		--from markdown+autolink_bare_uris+ascii_identifiers+tex_math_single_backslash-implicit_figures+smart \
		--output $@ \
		--highlight-style tango \
		--self-contained \
		--variable=mathspec \
		--include-in-header style/header.tex \
		--include-before-body style/body.tex

$(MD) : tmpdir/%.knit.md : tmpdir/%.Rmd | tmpdir
	R -e "rmarkdown::render('$^',clean=FALSE,run_pandoc=FALSE, knit_root_dir='..')"

$(TMP) : tmpdir/%.Rmd : %.Rmd | style/beamer.yaml style/header.tex style/r_setup.Rmd tmpdir
	cat style/beamer.yaml style/r_setup.Rmd $^ > $@


$(SOURCE) : sourcedir/%.md : tmpdir/%.knit.md | sourcedir
		/usr/bin/env pandoc \
		+RTS -K512m \
		-RTS $^ \
		--to markdown \
		--from markdown+autolink_bare_uris+ascii_identifiers+tex_math_single_backslash-implicit_figures \
		--output $@ \
		--highlight-style tango \
		--self-contained \
		--lua-filter=style/notefilter.lua


$(PPTX) : sourcedir/%.pptx : tmpdir/%.knit.md | sourcedir
		/usr/bin/env pandoc \
		+RTS -K512m \
		-RTS $^ \
		--to pptx \
		--from markdown+autolink_bare_uris+ascii_identifiers+tex_math_single_backslash-implicit_figures \
		--output $@ \
		--highlight-style tango \
		--self-contained \
		--lua-filter=style/notefilter.lua


sourcedir:
	mkdir $@

tmpdir:
	mkdir $@

pdf:
	mkdir $@

tex:
	mkdir $@

notetmp:
	mkdir $@

pdfnotes:
	mkdir $@