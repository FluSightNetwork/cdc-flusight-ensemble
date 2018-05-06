#!/usr/bin/env bash

# Script for generating real time ensemble files
set -e

# Download pinned [pkr](https://github.com/reichlab/pkr) version
echo "> Setting up R dependencies"
wget https://raw.githubusercontent.com/reichlab/pkr/6780f41cc9220d5f2593680a0e2e5501ccd2f152/pkr
sudo chmod +x pkr
sudo ./pkr --version
sudo ./pkr in --file pkrfile --global
Rscript ./scripts/make-real-time-ensemble-forecast-file.R $(node ./scripts/get-current-week.js)

git add ./model-forecasts/real-time-ensemble-models/*/*.csv
git add ./model-forecasts/submissions/target-type-based-weights/*.csv
git add ./model-forecasts/submissions/plots/*.pdf
git add ./plots/*.png
git diff-index --quiet HEAD || git commit -m "[TRAVIS] Ensemble files from travis"

# Pull if origin has new files
git pull $SSH_REPO master --no-edit
git push $SSH_REPO HEAD:master
