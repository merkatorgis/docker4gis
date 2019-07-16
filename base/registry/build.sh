#!/bin/bash
set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"

repo=$(basename "$(pwd)")
container="${DOCKER_USER}-${repo}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}"

echo; echo "Building ${image}"
if docker container rm -f "${container}" 2>/dev/null; then true; fi

if [ -d ./goproxy ]; then # building base
	which go
	cd ./goproxy
	CGO_ENABLED=0 GOOS=linux go build -a -tags netgo -ldflags '-w' .
	cd ..
	docker build -t "${image}" .
else # building upon base
	docker build -t "${image}" .
fi
