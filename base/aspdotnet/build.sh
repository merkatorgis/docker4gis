#!/bin/bash

IMAGE=${IMAGE:-docker4gis/$(basename "$(realpath .)")}
DOCKER_BASE=$DOCKER_BASE

mkdir -p conf
cp -r "$DOCKER_BASE"/.plugins "$DOCKER_BASE"/.docker4gis conf
docker image build \
    --build-arg DOCKER_USER="$DOCKER_USER" \
    --build-arg PGHOST="$PGHOST" \
    --build-arg PGHOSTADDR="$PGHOSTADDR" \
    --build-arg PGPORT="$PGPORT" \
    --build-arg PGDATABASE="$PGDATABASE" \
    --build-arg PGUSER="$PGUSER" \
    --build-arg PGPASSWORD="$PGPASSWORD" \
    -t "$IMAGE" .
rm -rf conf/.plugins conf/.docker4gis
