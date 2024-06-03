#!/bin/bash
set -e

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART
DEBUG=$DEBUG

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

mkdir -p "$FILEPORT"
mkdir -p "$RUNNER"

docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-e DEBUG="$DEBUG" \
	--mount type=bind,source="$FILEPORT",target=/fileport \
	--mount type=bind,source="$RUNNER",target=/runner \
	--network "$DOCKER_USER" \
	"$@" \
	-d "$IMAGE"
