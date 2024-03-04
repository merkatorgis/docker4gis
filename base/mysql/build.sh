#!/bin/bash

IMAGE=${IMAGE:-docker4gis/$(basename "$(realpath .)")}
DOCKER_BASE=$DOCKER_BASE

mkdir -p conf
cp -r "$DOCKER_BASE"/.plugins "$DOCKER_BASE"/.docker4gis conf
docker image build \
    --build-arg MYSQL_DATABASE="$MYSQL_DATABASE" \
    --build-arg MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    -t "$IMAGE" .
rm -rf conf/.plugins conf/.docker4gis
