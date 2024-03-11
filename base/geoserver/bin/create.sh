#!/bin/bash

GEOSERVER_VERSION='2.24.2'
GEOSERVER_EXTENSIONS='css printing pyramid'

image=docker.merkator.com/geoserver/bin:$GEOSERVER_VERSION

docker image build \
    --build-arg GEOSERVER_VERSION="$GEOSERVER_VERSION" \
    --build-arg GEOSERVER_EXTENSIONS="$GEOSERVER_EXTENSIONS" \
    -t "$image" \
    "$(dirname "$0")"

docker image push "$image"
