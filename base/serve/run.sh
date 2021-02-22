#!/bin/bash
set -e

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

fileport=$DOCKER_BINDS_DIR/fileport/$DOCKER_USER
mkdir -p "$fileport"

docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_USER="$DOCKER_USER" \
	--network "$DOCKER_USER" \
	-v "$(docker4gis/bind.sh "$fileport" /fileport)" \
	-d "$IMAGE"
