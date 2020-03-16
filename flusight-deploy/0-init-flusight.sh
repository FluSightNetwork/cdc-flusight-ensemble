#!/usr/bin/env bash

# Script to download and setup flusight directory structure
set -e

# Parse data model data files to flusight format
yarn
yarn run parse-data
# Replace already present data
rm -rf ./flusight-master/data
mv ./data ./flusight-master

cd ./flusight-master
yarn
node ./scripts/get-history.js
yarn run parse
yarn run test
cd .. # in flusight-deploy now
