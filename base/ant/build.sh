#!/bin/bash

src_dir="$1"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-api}"
DOCKER_TAG="${DOCKER_TAG:-latest}"

container="${DOCKER_CONTAINER:-$DOCKER_USER-api}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building ${image}"
docker container rm -f "${container}" 2>/dev/null

mkdir -p conf
rm -rf __src
cp -r "${src_dir}" __src
here=$(dirname "$0")
cp "${here}/Dockerfile" .
docker image build -t "${image}" .
rm -rf __src Dockerfile
