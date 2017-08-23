#!/usr/bin/env bash

set -e

if [ "$TRAVIS_COMMIT_MESSAGE" == "autogenerate scores.csv" ]; then
    echo "This is an auto commit from travis. Not doing anything."
    exit 0
fi

# Test data
npm install
npm run test

if [ "$TRAVIS_BRANCH" != "master" ]; then
    echo "Not on master. Not doing anything else."
    exit 0
fi

# Save some useful information
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

# Setup credentials
git config user.name "CI auto deploy"
git config user.email "abhinav.tushar.vs@gmail.com"
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in deploy_key.enc -out deploy_key -d
chmod 600 deploy_key
eval `ssh-agent -s`
ssh-add deploy_key

# All scripts are run from this path as root
cd ./flusight-deploy
bash ./0-init-flusight.sh
bash ./1-save-scores.sh
cd .. # in repo root now

# Push generated scores to master
git add ./scores.csv
git commit -m "autogenerate scores.csv"
git push $SSH_REPO HEAD:master

# Go back and build flusight
git checkout gh-pages || git checkout --orphan gh-pages
cd ./flusight-deploy
bash ./2-build-flusight.sh
cd .. # in repo root now

# Remove csvs
find . -name "*.csv" -type f -delete

git add .
git commit -m "Auto deploy to GitHub Pages: ${SHA}"

# Push to gh-pages
git push $SSH_REPO gh-pages --force
ssh-agent -k
