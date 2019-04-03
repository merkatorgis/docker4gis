#!/bin/bash
set -e

GEOSERVER_HOST="${GEOSERVER_HOST:-geoserver.merkator.com}"
DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-geoserver}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR}"
NETWORK_NAME="${NETWORK_NAME:-$DOCKER_USER-net}"

GEOSERVER_USER="${GEOSERVER_USER:-admin}"
GEOSERVER_PASSWORD="${GEOSERVER_PASSWORD:-geoserver}"

container="${GEOSERVER_CONTAINER:-$DOCKER_USER-gs}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"
here=$(dirname "$0")

if "$here/../start.sh" "${container}"; then exit; fi

mkdir -p "${DOCKER_BINDS_DIR}/secrets"
mkdir -p "${DOCKER_BINDS_DIR}/fileport"
mkdir -p "${DOCKER_BINDS_DIR}/runner"
mkdir -p "${DOCKER_BINDS_DIR}/certificates"
mkdir -p "${DOCKER_BINDS_DIR}/gwc"

"$here/../network.sh"
docker volume create "$container"
docker run --name $container \
	-e GEOSERVER_HOST=$GEOSERVER_HOST \
	-v $DOCKER_BINDS_DIR/secrets:/secrets \
	-v $DOCKER_BINDS_DIR/fileport:/fileport \
	-v $DOCKER_BINDS_DIR/certificates:/certificates \
	-v $DOCKER_BINDS_DIR/gwc:/geoserver/cache \
	-v $DOCKER_BINDS_DIR/runner:/util/runner/log \
	--mount source="$container",target=/geoserver/data/workspaces/dynamic \
	--network "$NETWORK_NAME" \
	-e "GEOSERVER_USER=${GEOSERVER_USER}" \
	-e "GEOSERVER_PASSWORD=${GEOSERVER_PASSWORD}" \
	"$@" \
	-d $image
