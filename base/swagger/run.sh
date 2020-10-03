#!/bin/bash
set -e

IMAGE=$IMAGE
CONTAINER=$CONTAINER

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

proxy=$PROXY_HOST
[ "$PROXY_PORT" ] && proxy=$proxy:$PROXY_PORT
API_URL=${API_URL:-https://$proxy/$DOCKER_USER/api}

docker container run --restart always --name "$CONTAINER" \
	-e DOCKER_USER="$DOCKER_USER" \
	--network "$DOCKER_USER" \
	-e API_URL="$API_URL" \
	"$@" \
	-d "$IMAGE"
