#!/bin/bash

docker image build \
    --build-arg DOCKER_REGISTRY="$DOCKER_REGISTRY" \
    --build-arg DOCKER_USER="$DOCKER_USER" \
    --build-arg DOCKER_REPO="$DOCKER_REPO" \
    --build-arg PGHOST="$PGHOST" \
    --build-arg PGHOSTADDR="$PGHOSTADDR" \
    --build-arg PGPORT="$PGPORT" \
    --build-arg PGDATABASE="$PGDATABASE" \
    --build-arg PGUSER="$PGUSER" \
    --build-arg PGPASSWORD="$PGPASSWORD" \
    -t "$DOCKER_IMAGE" .
