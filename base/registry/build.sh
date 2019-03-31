#!/bin/bash
set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-registry}"
DOCKER_TAG="${DOCKER_TAG:-latest}"

CONTAINER="$DOCKER_REPO"
IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"
docker container rm -f "${CONTAINER}" 2>/dev/null

if [ -d ./goproxy ]; then # building base
	which go
	cd ./goproxy
	CGO_ENABLED=0 GOOS=linux go build -a -tags netgo -ldflags '-w' .
	cd ..
	docker build -t "$IMAGE" .
else # building upon base
	docker build -t "$IMAGE" .
fi
