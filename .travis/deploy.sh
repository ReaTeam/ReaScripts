#!/bin/sh

set -e

cd "$(dirname "$0")"

echo $DEPLOY_KEY_PASSPHRASE | gpg --passphrase-fd 0 deploy_key.gpg

eval "$(ssh-agent -s)"
chmod 600 deploy_key
ssh-add deploy_key

git config push.default simple
git config user.name 'ReaTeam Bot'
git config user.email 'reateam-bot@cfillion.tk'
git remote add deploy 'git@github.com:ReaTeam/ReaScripts.git'

git fetch --unshallow || true
git checkout "$TRAVIS_BRANCH"

rvm $TRAVIS_RUBY_VERSION do reapack-index --commit

git push deploy "$TRAVIS_BRANCH"
