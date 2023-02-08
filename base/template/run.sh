#!/bin/bash
set -e

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

network=$CONTAINER
docker4gis/network.sh "$network"

fileport="$DOCKER_BINDS_DIR"/fileport/"$DOCKER_USER"
mkdir -p "$fileport"

volume=$CONTAINER
docker volume create "$volume" >/dev/null

docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-v "$(docker4gis/bind.sh "$fileport" /fileport)" \
	--mount source="$volume",target=/volume \
	--network "$network" \
	-d "$IMAGE" component_name "$@"
