#!/bin/bash

version=${1:?"version parameter not set"}

DOCKER_REPO=${2:-$DOCKER_REPO}
DOCKER_REPO=${DOCKER_REPO:?"DOCKER_REPO variable not set"}

# Note that this makes it okay to commit template Dockerfiles with a _latest_
# tag (FROM docker4gis/$DOCKER_REPO:latest), which is probably how you were
# testing extensions of your newly built base component image.
from="FROM docker4gis/$DOCKER_REPO"
search="$from:.*"
replace="$from:$version"
# -mindepth 2 to skip the Dockerfile in the current directory.
find . -mindepth 2 -name Dockerfile -exec sed -i "s|$search|$replace|ig" {} \;
