#!/bin/bash
set -e

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART
IP=$IP
FILEPORT=$FILEPORT
RUNNER=$RUNNER

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

GEOSERVER_USER=${GEOSERVER_USER:-admin}
GEOSERVER_PASSWORD=${GEOSERVER_PASSWORD:-geoserver}

XMS=${XMS:-256m}
XMX=${XMX:-2g}

GEOSERVER_PORT=$(docker4gis/port.sh "${GEOSERVER_PORT:-58080}")

# Make directory as the user running the run script, instead of letting the
# container create it as root.
GEOSERVER_WEB_CACHE=$DOCKER_BINDS_DIR/gwc/$DOCKER_USER
mkdir -p "$GEOSERVER_WEB_CACHE"

docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_USER="$DOCKER_USER" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-e XMS="$XMS" \
	-e XMX="$XMX" \
	-e GEOSERVER_USER="$GEOSERVER_USER" \
	-e GEOSERVER_PASSWORD="$GEOSERVER_PASSWORD" \
	--mount type=bind,source="$FILEPORT",target=/fileport \
	--mount type=bind,source="$RUNNER",target=/runner \
	--mount type=bind,source="$GEOSERVER_WEB_CACHE",target=/geoserver/cache \
	-p "$GEOSERVER_PORT":8080 \
	--network "$DOCKER_USER" \
	--ip "$IP" \
	"$@" \
	-d "$IMAGE"
