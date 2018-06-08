TEXFILE= comparison-manuscript
STATICFILEDIR= ./static-figures
RDIR= ./code

# define figures as targets so they can be called with all
# PDFFIGS := $(wildcard $(FIGDIR)/*.pdf) 

## define the full make, explicitly referencing all targets
all: view clean 

###########################
### begin main PDF make ###
###########################

view: pdf
	open $(TEXFILE).pdf &

pdf: $(TEXFILE).pdf

## knit the manuscript tex --> pdf
## dependencies here are static files, manually updated, not used in reproducible analyses
$(TEXFILE).pdf: $(TEXFILE).tex ../flusightnetwork.bib static-figures/model-table.tex static-figures/timezero-sketch.pdf
	pdflatex $(TEXFILE)
	bibtex $(TEXFILE)
	pdflatex $(TEXFILE)
	pdflatex $(TEXFILE)

## knit Rnw --> tex
$(TEXFILE).tex: $(TEXFILE).Rnw data/all-target-bounds.csv ../../scores/target-multivals.csv ../../scores/scores.csv data/delay-model-coefs.rds 
	Rscript \
	  -e "library(knitr)" \
	  -e "knitr::knit('$<','$@')"

# clean up
clean: 
#	-rm -f $(TEXFILE).aux
#	-rm -f $(TEXFILE).bbl
	-rm -f $(TEXFILE).blg
	-rm -f $(TEXFILE).log
	-rm -f $(TEXFILE).out
	-rm -f $(TEXFILE).toc

### end main PDF make ###

# the file defining weekly bounds for evaluation
data/all-target-bounds.csv:  $(RDIR)/create-target-bounds.R ../../baselines/wILI_Baseline.csv ../../scripts/create-scoring-period.R
	R CMD BATCH $< 

## the delay analysis - only using one rds file as the target, the other lagged_truth.rds is also output by this script
data/delay-model-coefs.rds: $(RDIR)/delay-model-coefs.R data/truth-with-lags.csv
	R CMD BATCH $< 

## the master scores table - not included in this build
## instructions for running the script: https://github.com/FluSightNetwork/cdc-flusight-ensemble/wiki/Code-Documentation
# ../../scores/scores.csv: scripts/generate-scores.js 

## a 'truth table' with true values each forecast - not included in this build
#../../scores/target-multivals.csv: ../../scripts/calculate-targets.R
#	R CMD BATCH $< 

.PHONY: all view clean
