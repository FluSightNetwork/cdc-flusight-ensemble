TEXFILE= ensemble-manuscript
STATICFILEDIR= ./static-content
RDIR= ./code

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
$(TEXFILE).pdf: $(TEXFILE).tex ../flusightnetwork.bib static-content/model-table.tex 
	pdflatex $(TEXFILE)
	bibtex $(TEXFILE)
	pdflatex $(TEXFILE)
	pdflatex $(TEXFILE)

## knit Rnw --> tex
$(TEXFILE).tex: $(TEXFILE).Rnw data/all-target-bounds.csv ../../scores/target-multivals.csv ../../scores/scores.csv 
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

## the master scores table - not included in this build
## instructions for running the script: https://github.com/FluSightNetwork/cdc-flusight-ensemble/wiki/Code-Documentation
# ../../scores/scores.csv: scripts/generate-scores.js 

## a 'truth table' with true values each forecast - not included in this build
#../../scores/target-multivals.csv: ../../scripts/calculate-targets.R
#	R CMD BATCH $< 

## weights file that was built before 2017/2018 season
# ../../weights/target-type-based-weights.csv: ../../scripts/calculate-weights.R
#	R CMD BATCH $< 

.PHONY: all view clean
