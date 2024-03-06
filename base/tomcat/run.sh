#!/bin/bash
set -e

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART
IP=$IP

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

XMS=${XMS:-256m}
XMX=${XMX:-2g}

TOMCAT_PORT=$(docker4gis/port.sh "${TOMCAT_PORT:-9090}")

mkdir -p "$FILEPORT"
mkdir -p "$RUNNER"

docker volume create "$CONTAINER" >/dev/null
docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_USER="$DOCKER_USER" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-e XMS="$XMS" \
	-e XMX="$XMX" \
	--mount source="$CONTAINER",target=/host \
	--mount type=bind,source="$FILEPORT",target=/fileport \
	--mount type=bind,source="$RUNNER",target=/runner \
	-p "$TOMCAT_PORT":8080 \
	--network "$DOCKER_USER" \
	--ip "$IP" \
	"$@" \
	-d "$IMAGE"
