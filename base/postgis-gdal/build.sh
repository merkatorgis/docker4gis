#!/usr/bin/bash

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkator}"
DOCKER_REPO="${DOCKER_REPO:-postgis-gdal}"
DOCKER_TAG="${DOCKER_TAG:-latest}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

HERE=$(dirname "$0")
cp -r "$HERE/../include" "$HERE/conf"
docker build -t $IMAGE .
rm -rf "$HERE/conf/include"
