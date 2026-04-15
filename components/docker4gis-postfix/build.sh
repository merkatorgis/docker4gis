#!/bin/bash

docker image build \
	--build-arg DOCKER_REGISTRY="$DOCKER_REGISTRY" \
	--build-arg DOCKER_USER="$DOCKER_USER" \
	--build-arg DOCKER_REPO="$DOCKER_REPO" \
	-t "$DOCKER_IMAGE" .
