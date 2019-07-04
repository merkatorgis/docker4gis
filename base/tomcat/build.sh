#!/bin/bash

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-tomcat}"
DOCKER_TAG="${DOCKER_TAG:-latest}"

container="${TOMCAT_CONTAINER:-$DOCKER_USER-tc}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building ${image}"
docker container rm -f "${container}" 2>/dev/null

here=$(dirname "$0")

mkdir -p conf
cp -r "${here}/../plugins" "conf"
docker image build -t "${image}" .
rm -rf "conf/plugins"
