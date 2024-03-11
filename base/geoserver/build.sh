#!/bin/bash

GEOSERVER_VERSION='2.24.2'
GEOSERVER_EXTENSIONS='css printing pyramid'

IMAGE=${IMAGE:-docker4gis/$(basename "$(realpath .)")}
DOCKER_BASE=$DOCKER_BASE

mkdir -p conf
if [ -d conf/DOCKER_USER ] && [ "$DOCKER_USER" ]; then
    # Rename template conf dir to actual DOCKER_USER value.
    mv conf/DOCKER_USER conf/"$DOCKER_USER"
fi
cp -r "$DOCKER_BASE"/.plugins "$DOCKER_BASE"/.docker4gis conf
docker image build \
    --build-arg GEOSERVER_VERSION="$GEOSERVER_VERSION" \
    --build-arg GEOSERVER_EXTENSIONS="$GEOSERVER_EXTENSIONS" \
    --build-arg GEOSERVER_EXTRA_EXTENSIONS="$GEOSERVER_EXTRA_EXTENSIONS" \
    -t "$IMAGE" .
rm -rf conf/.plugins conf/.docker4gis
