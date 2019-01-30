#!/bin/bash
DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER}"
repo="$1"
container="$2"

here=$(dirname "$0")
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}:latest"

"${here}/rename.sh" "${image}" "${container}" force
sudo docker image pull "${image}"
