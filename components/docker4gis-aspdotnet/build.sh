#!/bin/bash

docker image build \
	--build-arg DOTNET_PROJECT="$DOTNET_PROJECT" \
	--build-arg DOCKER_USER="$DOCKER_USER" \
	-t "$IMAGE" .
