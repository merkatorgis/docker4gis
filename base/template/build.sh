#!/bin/bash

docker image build \
	--build-arg DOCKER_USER="$DOCKER_USER" \
	-t "$IMAGE" .
