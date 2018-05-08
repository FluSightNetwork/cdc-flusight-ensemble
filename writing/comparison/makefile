TEXFILE= comparison-manuscript
STATICFILEDIR= ./static-figures
RDIR= ./code

## should be made to rely on scores.csv and maybe target-multivals.csv in ../../scores/

# define figures as targets so they can be called with all
# PDFFIGS := $(wildcard $(FIGDIR)/*.pdf) 

## define the full make, explicitly referencing all targets
all: $(TEXFILE).pdf $(TEXFILE).tex data/all-target-bounds.csv data/delay-model-coefs.rds view clean 

###########################
### begin main PDF make ###
###########################

pdf: $(TEXFILE).pdf

## knit Rnw --> tex
$(TEXFILE).tex: $(TEXFILE).Rnw data/all-target-bounds.csv ../../scores/target-multivals.csv ../../scores/scores.csv data/delay-model-coefs.rds ../flusightnetwork.bib static-figures/model-table.tex static-figures/timezero-sketch.pdf
	Rscript \
	  -e "library(knitr)" \
	  -e "knitr::knit('$<','$@')"

## knit the manuscript tex --> pdf
$(TEXFILE).pdf: $(TEXFILE).tex 
	pdflatex $(TEXFILE)
	bibtex $(TEXFILE)
	pdflatex $(TEXFILE)
	pdflatex $(TEXFILE)

# View main tex file
view: $(TEXFILE).pdf
	open $(TEXFILE).pdf &

# clean up
clean: 
	-rm $(TEXFILE).aux
	-rm $(TEXFILE).bbl
	-rm $(TEXFILE).blg
	-rm $(TEXFILE).log
	-rm $(TEXFILE).out
	-rm $(TEXFILE).toc

### end main PDF make ###

# the file defining weekly bounds for evaluation
data/all-target-bounds.csv:  $(RDIR)/create-target-bounds.R ../../baselines/wILI_Baselines.csv ../../scripts/create-scoring-period.R
	R CMD BATCH $< 

## the delay analysis - only using one rds file as the target, the other lagged_truth.rds is also output by this script
data/delay-model-coefs.rds: $(RDIR)/delay-model-coefs.R data/truth-with-lags.csv
	R CMD BATCH $< 

## the master scores table - not included in this build
# ../../scores/scores.csv: scripts/generate-scores.js 

## a 'truth table' with true values each forecast - not included in this build
#../../scores/target-multivals.csv: ../../scripts/calculate-targets.R
#	R CMD BATCH $< 

.PHONY: all clean
