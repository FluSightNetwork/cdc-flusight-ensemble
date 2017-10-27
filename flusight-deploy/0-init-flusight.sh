#!/usr/bin/env bash

# Script to download and setup flusight directory structure
set -e

# Download flusight master
wget "https://github.com/reichlab/flusight/archive/master.zip"
unzip ./master.zip
rm ./master.zip

# Parse data model data files to flusight format
yarn
yarn run parse-data
# Replace already present data
rm -rf ./flusight-master/data
mv ./data ./flusight-master

cd ./flusight-master
yarn
yarn run get-actual
yarn run parse
yarn run test
cd .. # in flusight-deploy now
