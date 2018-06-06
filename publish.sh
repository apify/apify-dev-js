#!/bin/bash

set -e

# Notes:
# - develop branch gets published as beta package and master as the latest

RED='\033[0;31m'
NC='\033[0m' # No Color

PACKAGE_NAME=`node -pe "require('./package.json').name"`
PACKAGE_VERSION=`node -pe "require('./package.json').version"`
BRANCH=`git status | grep 'On branch' | cut -d ' ' -f 3`
BRANCH_UP_TO_DATE=`git status | grep 'nothing to commit' | tr -s \n ' '`;
GIT_TAG="v${PACKAGE_VERSION}"

if [ -z "${BRANCH_UP_TO_DATE}" ]; then
    printf "${RED}You have uncommitted changes!${NC}\n"
    exit 1
fi

echo "Pushing to git ..."
git push

# Master gets published as LATEST if that version doesn't exists yet and retagged as LATEST otherwise.
if [ "${BRANCH}" = "master" ]; then
    EXISTING_NPM_VERSION=$(npm view ${PACKAGE_NAME} versions | grep ${PACKAGE_VERSION} | tee) # Using tee to swallow non-zero exit code
    if [ -z "${EXISTING_NPM_VERSION}" ]; then
        printf "${RED}Version ${PACKAGE_VERSION} was not yet published on NPM. Note that you can only publish to NPM from \"develop\" branch!${NC}\n"
        exit 1
    else
        echo "Tagging version ${PACKAGE_VERSION} on NPM with tag \"latest\" ..."
        RUNNING_FROM_SCRIPT=1 npm dist-tag add ${PACKAGE_NAME}@${PACKAGE_VERSION} latest
    fi

# Any other branch gets published as BETA and we don't allow to override tag of existing version.
else
    echo "Publishing version ${PACKAGE_VERSION} with tag \"beta\" ..."
    npm run build
    npm run test
    cp package.json .npmignore README.md LICENSE build/
    cd build && ls && npm i && RUNNING_FROM_SCRIPT=1 npm publish --tag beta

    echo "Tagging git commit with ${GIT_TAG} ..."
    git tag ${GIT_TAG}
    git push origin ${GIT_TAG}
    echo "Git tag: ${GIT_TAG} created."
fi

echo "Done."
