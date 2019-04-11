#!/bin/bash
DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER}"
repo="$1"
container="$2"

here=$(dirname "$0")
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}:latest"

docker container rm -f "${container}" 2>/dev/null
docker image pull "${image}"
