#!/bin/bash

tag="${1}"
image="${2}"

image="${DOCKER_REGISTRY}${DOCKER_USER}/${image}"

docker image push "${image}:latest"
docker image push "${image}:${tag}"
