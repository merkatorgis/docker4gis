#!/bin/bash
set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-cron}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR}"
GEOSERVER_CONTAINER="${GEOSERVER_CONTAINER:-$DOCKER_USER-gs}"
GEOSERVER_USER="${GEOSERVER_USER:-admin}"
GEOSERVER_PASSWORD="${GEOSERVER_PASSWORD:-geoserver}"
NETWORK_NAME="${NETWORK_NAME:-$DOCKER_USER-net}"

container="${CRON_CONTAINER:-$DOCKER_USER-cr}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"
here=$(dirname "$0")

if "$here/../start.sh" "${container}"; then exit; fi

mkdir -p "${DOCKER_BINDS_DIR}/secrets"
mkdir -p "${DOCKER_BINDS_DIR}/fileport"
mkdir -p "${DOCKER_BINDS_DIR}/runner"

"$here/../network.sh"
docker run --name $container \
	-v $DOCKER_BINDS_DIR/secrets:/secrets \
	-v $DOCKER_BINDS_DIR/fileport:/fileport \
	-v $DOCKER_BINDS_DIR/runner:/util/runner/log \
	--network "$NETWORK_NAME" \
	-e "GEOSERVER_CONTAINER=${GEOSERVER_CONTAINER}" \
	-e "GEOSERVER_USER=${GEOSERVER_USER}" \
	-e "GEOSERVER_PASSWORD=${GEOSERVER_PASSWORD}" \
	"$@" \
	-d $image
