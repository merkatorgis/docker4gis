#!/bin/bash
set -e

src_dir=$1

IMAGE=$IMAGE
CONTAINER=$CONTAINER

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

docker volume create "$CONTAINER" >/dev/null
docker container run --rm --name "$CONTAINER" \
    --mount type=bind,source="$src_dir",target=/src \
    --mount source="$CONTAINER",target=/root/.m2 \
    "$IMAGE"
