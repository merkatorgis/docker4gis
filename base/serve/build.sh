#!/bin/bash
set -e

wwwroot=$1

DOCKER_BASE=$DOCKER_BASE
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=${DOCKER_USER:-docker4gis}

repo=$(basename "$(pwd)")
image=$DOCKER_REGISTRY$DOCKER_USER/$repo

build() {
    docker image build \
        -t "$image" .
}

mkdir -p conf
cp -r "$DOCKER_BASE"/plugins "$DOCKER_BASE"/.docker4gis conf
if [ "$wwwroot" ]; then
    cp Dockerfile "$wwwroot"
    pushd "$wwwroot"
    build
    rm Dockerfile
    popd
else
    build
fi
rm -rf conf/plugins conf/.docker4gis
