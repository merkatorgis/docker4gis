#!/bin/bash
set -e

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART
IP=$IP
FILEPORT=$FILEPORT
RUNNER=$RUNNER

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

POSTFIX_DESTINATION=$POSTFIX_DESTINATION

POSTFIX_PORT=$(docker4gis/port.sh "${POSTFIX_PORT:-25}")

docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_USER="$DOCKER_USER" \
	-e "$(docker4gis/noop.sh DESTINATION "$POSTFIX_DESTINATION")" \
	--mount type=bind,source="$FILEPORT",target=/fileport \
	--mount type=bind,source="$RUNNER",target=/runner \
	-p "$POSTFIX_PORT":25 \
	--network "$DOCKER_USER" \
	--ip "$IP" \
	-d "$IMAGE"
