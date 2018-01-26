TEXFILE= comparison-manuscript
FIGDIR= ./figures
RDIR= ./code

# define figures as targets so they can be called with all
PDFFIGS := $(wildcard $(FIGDIR)/*.pdf)

## define the full make, explicitly referencing all targets
all: $(TEXFILE).pdf $(PDFFIGS) view

## the manuscript
$(TEXFILE).pdf: $(TEXFILE).tex $(PDFFIGS)
	pdflatex $(TEXFILE)
	bibtex $(TEXFILE)
	pdflatex $(TEXFILE)
	pdflatex $(TEXFILE)

# the figures, in order for this to work, might need the PDF file to exist...
$(FIGDIR)/%.pdf: $(RDIR)/%.R
	R CMD BATCH $< 

# View main tex file
view: $(TEXFILE).pdf
	open $(TEXFILE).pdf &
	
.PHONY: all clean
