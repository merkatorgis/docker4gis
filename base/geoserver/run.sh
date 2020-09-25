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

GEOSERVER_HOST=${GEOSERVER_HOST:-geoserver.merkator.com}
GEOSERVER_USER=${GEOSERVER_USER:-admin}
GEOSERVER_PASSWORD=${GEOSERVER_PASSWORD:-geoserver}

XMS=${XMS:-256m}
XMX=${XMX:-2g}

GEOSERVER_PORT=$(docker4gis/port.sh "${GEOSERVER_PORT:-58080}")

docker volume create "$container" >/dev/null
docker container run --restart always --name "$container" \
	-e DOCKER_USER="$DOCKER_USER" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-e XMS="$XMS" \
	-e XMX="$XMX" \
	-e GEOSERVER_HOST="$GEOSERVER_HOST" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/secrets /secrets)" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/certificates /certificates)" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/fileport /fileport)" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/runner /util/runner/log)" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/gwc /geoserver/cache)" \
	--mount source="$container",target=/geoserver/data/workspaces/dynamic \
	--network "$DOCKER_USER" \
	-e GEOSERVER_USER="$GEOSERVER_USER" \
	-e GEOSERVER_PASSWORD="$GEOSERVER_PASSWORD" \
	-p "$GEOSERVER_PORT":8080 \
	"$@" \
	-d "$image"
