#!/usr/bin/env bash

set -e
# Script for building and hosting visualizer

echo "> Building visualizer"
git checkout gh-pages || git checkout --orphan gh-pages
cd ./flusight-deploy
bash ./0-init-flusight.sh
bash ./1-patch-flusight.sh
bash ./2-build-flusight.sh
cd .. # in repo root now

# Remove CSVs
find . -name "*.csv" -type f -delete

git add .
git commit -m "[TRAVIS] Auto deploy to GitHub pages from travis: ${SHA}"

echo "> Pushing visualizer to gh-pages"
git push $SSH_REPO gh-pages --force
