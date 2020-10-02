#!/bin/bash

IMAGE=${IMAGE:-docker4gis/$(basename "$(realpath .)")}
DOCKER_BASE=$DOCKER_BASE
DOCKER_USER=$DOCKER_USER

mkdir -p conf
cp -r "$DOCKER_BASE"/.plugins "$DOCKER_BASE"/.docker4gis conf
docker image build \
	--build-arg DOCKER_USER="$DOCKER_USER" \
	-t "$IMAGE" .
rm -rf conf/.plugins conf/.docker4gis
