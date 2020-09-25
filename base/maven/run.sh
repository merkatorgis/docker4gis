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
    -v "$(docker4gis/bind.sh "$src_dir" /src)" \
    --mount source="$CONTAINER",target=/root/.m2 \
    "$IMAGE"
