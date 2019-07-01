#!/bin/bash

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-maven}"
DOCKER_TAG="${DOCKER_TAG:-latest}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

docker image build -t "${IMAGE}" .
