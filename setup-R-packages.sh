#!/usr/bin/env bash

# Script to setup packages required for R code
set -e

sudo Rscript -e "install.packages('devtools', repos='http://cran.us.r-project.org')"
sudo Rscript -e "devtools::install_github('hrbrmstr/cdcfluview')"
sudo Rscript -e "devtools::install_github('jarad/FluSight')"
sudo Rscript -e "install.packages(c('dplyr', 'purrr', 'stringr'), repos='http://cran.us.r-project.org')"
