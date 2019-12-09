#!/bin/bash
set -x #echo on

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-mapservices}"

repo=$(basename "$(pwd)")
container="${DOCKER_USER}-${repo}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}"

echo; echo "Building ${image}"
docker container rm -f "${container}" 2>/dev/null

HERE=$(dirname "$0")

docker image build -t "${image}" .
