#!/bin/bash
set -e

DOCKER_BASE="$DOCKER_BASE"
DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="${DOCKER_USER:-docker4gis}"

repo=package
container="$DOCKER_USER-$repo"
image="$DOCKER_REGISTRY$DOCKER_USER/$repo"

echo; echo "Building $image"
docker container rm -f "$container" 2>/dev/null
docker container rm -f "$DOCKER_USER-api" 2>/dev/null

mkdir -p conf
cp -r "$DOCKER_BASE"/plugins "$DOCKER_BASE"/utils "conf"
docker image build \
    -t "${image}" .
rm -rf "conf/plugins" "conf/utils"
