#!/bin/bash
set -e

IMAGE=$IMAGE
CONTAINER=$CONTAINER
DOCKER_ENV=$DOCKER_ENV
RESTART=$RESTART
NETWORK=$NETWORK
FILEPORT=$FILEPORT
VOLUME=$VOLUME

docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-v "$(docker4gis/bind.sh "$FILEPORT" /fileport)" \
	--mount source="$VOLUME",target=/volume \
	--network "$NETWORK" \
	-d "$IMAGE" component_name "$@"
