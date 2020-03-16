#!/usr/bin/env bash

# Script for handling xpull triggers from another repo
# This only gets called from travis api calls using trigger.sh in xpull
set -e

# Save some useful information
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

# Setup deploy keys
git config user.name "CI auto deploy"
git config user.email "lepisma@fastmail.com"
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in deploy_key.enc -out deploy_key -d
chmod 600 deploy_key
eval `ssh-agent -s`
ssh-add deploy_key

# Deleting the private key so that we don't accidentally push it back
rm deploy_key

echo "This is a trigger from another repository."
npm install -g "reichlab/xpull"
xpull --repo "reichlab/2017-2018-cdc-flu-contest" --message "[TRAVIS] Xpulled files from travis"

# Pull if origin has new files
git pull $SSH_REPO master --no-edit
git push $SSH_REPO HEAD:master
ssh-agent -k
