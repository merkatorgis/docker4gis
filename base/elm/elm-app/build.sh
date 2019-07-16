#!/bin/bash
set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"

repo=$(basename "$(pwd)")
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}"

echo; echo "Building ${image}"

docker image build -t "${image}" .
