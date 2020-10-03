#!/bin/bash
set -e

wwwroot=$1

IMAGE=${IMAGE:-docker4gis/$(basename "$(realpath .)")}
DOCKER_BASE=$DOCKER_BASE

build() {
    docker image build \
        -t "$IMAGE" .
}

mkdir -p conf
cp -r "$DOCKER_BASE"/.plugins "$DOCKER_BASE"/.docker4gis conf
if [ "$wwwroot" ]; then
    cp Dockerfile "$wwwroot"
    pushd "$wwwroot"
    build
    rm Dockerfile
    popd
else
    build
fi
rm -rf conf/.plugins conf/.docker4gis
