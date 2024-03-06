#!/bin/bash

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

mkdir -p "$FILEPORT"

docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_USER="$DOCKER_USER" \
	--mount type=bind,source="$FILEPORT",target=/fileport \
	--network "$DOCKER_USER" \
	"$@" \
	-d "$IMAGE"
