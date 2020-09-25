#!/bin/bash

DOCKER_BASE=$DOCKER_BASE
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=${DOCKER_USER:-docker4gis}

repo=$(basename "$(pwd)")
image=$DOCKER_REGISTRY$DOCKER_USER/$repo

mkdir -p conf
cp -r "$DOCKER_BASE"/plugins "$DOCKER_BASE"/.docker4gis conf
docker image build \
    -t "$image" .
rm -rf conf/plugins conf/.docker4gis
