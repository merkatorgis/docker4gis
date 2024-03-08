#!/bin/bash

IMAGE=${IMAGE:-docker4gis/$(basename "$(realpath .)")}
DOCKER_BASE=$DOCKER_BASE

mkdir -p conf
if [ -d conf/DOCKER_USER ] && [ "$DOCKER_USER" ]; then
    # rename template conf dir to actual DOCKER_USER value
    mv conf/DOCKER_USER conf/"$DOCKER_USER"
fi
cp -r "$DOCKER_BASE"/.plugins "$DOCKER_BASE"/.docker4gis conf
docker image build \
    --build-arg GEOSERVER_EXTRA_EXTENSIONS="$GEOSERVER_EXTRA_EXTENSIONS" \
    -t "$IMAGE" .
rm -rf conf/.plugins conf/.docker4gis
