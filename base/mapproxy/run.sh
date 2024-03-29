#!/bin/bash
set -e

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

docker volume create "$CONTAINER" >/dev/null
docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_USER="$DOCKER_USER" \
	--network "$DOCKER_USER" \
	--mount source="$CONTAINER",target=/srv/mapproxy/cache_data \
	"$@" \
	-d "$IMAGE"
