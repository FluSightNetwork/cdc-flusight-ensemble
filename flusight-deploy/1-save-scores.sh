#!/usr/bin/env bash

# Generate a csv file for scores in the project root
set -e

# in flusight-deploy now
cd ./flusight-master
npm run get-scores
yes | cp ./scripts/assets/scores.csv ../../ # Copy to repo root
cd .. # in flusight-deploy now
