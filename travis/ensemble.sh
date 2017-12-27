#!/usr/bin/env bash

# Script for generating real time ensemble files
set -e

# Download pinned [pkr](https://github.com/lepisma/pkr) version
echo "> Setting up R dependencies"
wget https://raw.githubusercontent.com/lepisma/pkr/cea19da312d66ec53508859acea15b41c8ba9979/pkr
sudo chmod +x pkr
sudo ./pkr --version
sudo ./pkr in --file pkrfile --global

Rscript ./scripts/make-real-time-ensemble-forecast-file.R $(node ./scripts/get-current-week.js)

git add ./model-forecasts/real-time-ensemble-models/*/*.csv
git add ./model-forecasts/submissions/target-type-based-weights/*.csv
git add ./model-forecasts/submissions/plots/*.pdf
git diff-index --quiet HEAD || git commit -m "[TRAVIS] Ensemble files from travis"
git push $SSH_REPO HEAD:master
