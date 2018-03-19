TEXFILE= comparison-manuscript
FIGDIR= ./figures
STATICFILEDIR= ./static-figures
RDIR= ./code

## should be made to rely on scores.csv and maybe target-multivals.csv in ../../scores/

# define figures as targets so they can be called with all
PDFFIGS := $(wildcard $(FIGDIR)/*.pdf) 

## define the full make, explicitly referencing all targets
all: $(TEXFILE).pdf $(TEXFILE).tex $(PDFFIGS) data/all-target-bounds.csv ./static-figures/score-by-model-type.tex view clean 

pdf: $(TEXFILE).pdf

clean: 
	-rm $(TEXFILE).aux
	-rm $(TEXFILE).bbl
	-rm $(TEXFILE).blg
	-rm $(TEXFILE).log
	-rm $(TEXFILE).out
	-rm $(TEXFILE).toc

## knit Rnw --> tex
$(TEXFILE).tex: $(TEXFILE).Rnw $(PDFFIGS) $(wildcard $(STATICFILEDIR)/*) 
	Rscript \
	  -e "library(knitr)" \
	  -e "knitr::knit('$<','$@')"

## knit the manuscript tex --> pdf
$(TEXFILE).pdf: $(TEXFILE).tex 
	pdflatex $(TEXFILE)
	bibtex $(TEXFILE)
	pdflatex $(TEXFILE)
	pdflatex $(TEXFILE)

# the figures, in order for this to work, need the PDF file to exist...
$(FIGDIR)/%.pdf: $(RDIR)/%.R data/all-target-bounds.csv
	R CMD BATCH $< 

# the file defining weekly bounds for evaluation
data/all-target-bounds.csv:  $(RDIR)/create-target-bounds.R
	R CMD BATCH $< 

# a table
./static-figures/score-by-model-type.tex: $(RDIR)/score-by-model-type.R
	R CMD BATCH $< 

# View main tex file
view: $(TEXFILE).pdf
	open $(TEXFILE).pdf &
	
.PHONY: all clean
