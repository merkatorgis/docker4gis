#!/bin/bash

docker image build \
	--build-arg DOCKER_USER="$DOCKER_USER" \
	--build-arg PGDATABASE="$PGDATABASE" \
	-t "$IMAGE" .
