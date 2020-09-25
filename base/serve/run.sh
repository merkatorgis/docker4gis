#!/bin/bash
set -e

repo=$1
tag=$2
shift 2

DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

container=$DOCKER_USER-$repo
image=$DOCKER_REGISTRY$DOCKER_USER/$repo:$tag

docker container run --restart always --name "$container" \
	-e DOCKER_USER="$DOCKER_USER" \
	--network "$DOCKER_USER" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/fileport/"$DOCKER_USER" /fileport)" \
	-d "$image"
