#!/bin/bash

set -e

if [ "$TRAVIS_BRANCH" != "master" ]; then
    echo "Not master, skipping."
    exit 0
fi

# Save some useful information
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

# Run deployment steps
git checkout gh-pages || git checkout --orphan gh-pages


# All scripts are run from this path as root
cd ./flusight-deploy
bash ./build-flusight.sh
rm -rf ./flusight-master
cd .. # at repo root
# Remove csvs
find . -name "*.csv" -type f -delete

git config user.name "CI auto deploy"
git config user.email "abhinav.tushar.vs@gmail.com"

git add .
git commit -m "Auto deploy to GitHub Pages: ${SHA}"

# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in deploy_key.enc -out deploy_key -d
chmod 600 deploy_key
eval `ssh-agent -s`
ssh-add deploy_key

# Push to gh-pages
git push $SSH_REPO gh-pages --force
ssh-agent -k
