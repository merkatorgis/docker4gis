#!/bin/bash
set -e

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

GEOSERVER_CONTAINER=${GEOSERVER_CONTAINER:-$DOCKER_USER-geoserver}
GEOSERVER_USER=${GEOSERVER_USER:-admin}
GEOSERVER_PASSWORD=${GEOSERVER_PASSWORD:-geoserver}

docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_USER="$DOCKER_USER" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	--mount type=bind,source="$DOCKER_BINDS_DIR"/secrets,target=/secrets \
	--mount type=bind,source="$DOCKER_BINDS_DIR"/fileport,target=/fileport \
	--mount type=bind,source="$DOCKER_BINDS_DIR"/runner,target=/util/runner/log \
	--network "$DOCKER_USER" \
	-e "GEOSERVER_CONTAINER=$GEOSERVER_CONTAINER" \
	-e "GEOSERVER_USER=$GEOSERVER_USER" \
	-e "GEOSERVER_PASSWORD=$GEOSERVER_PASSWORD" \
	"$@" \
	-d "$IMAGE"
