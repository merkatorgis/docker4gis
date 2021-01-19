#!/bin/bash
set -e

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

POSTFIX_DESTINATION=$POSTFIX_DESTINATION

POSTFIX_PORT=$(docker4gis/port.sh "${POSTFIX_PORT:-25}")

docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_USER="$DOCKER_USER" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/fileport /fileport)" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/runner /util/runner/log)" \
	-p "$POSTFIX_PORT":25 \
	-e "$(docker4gis/noop.sh DESTINATION "$POSTFIX_DESTINATION")" \
	--network "$DOCKER_USER" \
	-d "$IMAGE"
