#!/bin/bash

DOCKER_BASE="$DOCKER_BASE"
DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="${DOCKER_USER:-docker4gis}"

repo=proxy
image="$DOCKER_REGISTRY""$DOCKER_USER"/"$repo"

mkdir -p conf
cp -r "$DOCKER_BASE"/plugins "$DOCKER_BASE"/.docker4gis conf
if [ -d goproxy ]; then
	# Build base image.
	goproxy/builder/run.sh &&
		docker image build -t "$image" .
else
	# Build app image upon base image.
	docker image build \
		--build-arg DOCKER_USER="$DOCKER_USER" \
		-t "$image" .
fi
rm -rf conf/plugins conf/.docker4gis
