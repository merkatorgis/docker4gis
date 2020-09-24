#!/bin/bash
set -e

repo="$1"
tag="$2"
shift 2

DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="$DOCKER_USER"
DOCKER_ENV="$DOCKER_ENV"
DOCKER_BINDS_DIR="$DOCKER_BINDS_DIR"

container="$DOCKER_USER"-"$repo"
image="$DOCKER_REGISTRY""$DOCKER_USER"/"$repo":"$tag"

GEOSERVER_CONTAINER="${GEOSERVER_CONTAINER:-$DOCKER_USER-geoserver}"
GEOSERVER_USER="${GEOSERVER_USER:-admin}"
GEOSERVER_PASSWORD="${GEOSERVER_PASSWORD:-geoserver}"

docker container run --restart always --name "$container" \
	-e DOCKER_USER="$DOCKER_USER" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/secrets /secrets)" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/fileport /fileport)" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/runner /util/runner/log)" \
	--network "$DOCKER_USER" \
	-e "GEOSERVER_CONTAINER=$GEOSERVER_CONTAINER" \
	-e "GEOSERVER_USER=$GEOSERVER_USER" \
	-e "GEOSERVER_PASSWORD=$GEOSERVER_PASSWORD" \
	"$@" \
	-d "$image"
