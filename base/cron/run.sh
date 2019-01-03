#!/bin/bash
set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkator}"
DOCKER_REPO="${DOCKER_REPO:-cron}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR:-d:/Docker/binds}"
CONTAINER="${CONTAINER:-$DOCKER_USER-cr}"
GEOSERVER_CONTAINER="${GEOSERVER_CONTAINER:-$DOCKER_USER-gs}"
GEOSERVER_USER="${GEOSERVER_USER:-admin}"
GEOSERVER_PASSWORD="${GEOSERVER_PASSWORD:-geoserver}"
NETWORK_NAME="${NETWORK_NAME:-$DOCKER_USER-net}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

mkdir -p "${DOCKER_BINDS_DIR}/secrets"
mkdir -p "${DOCKER_BINDS_DIR}/fileport"
mkdir -p "${DOCKER_BINDS_DIR}/runner"

echo; echo "Running $CONTAINER from $IMAGE"
HERE=$(dirname "$0")
if ("$HERE/../rename.sh" "$IMAGE" "$CONTAINER"); then
	"$HERE/../network.sh"
	docker run --name $CONTAINER \
		-v $DOCKER_BINDS_DIR/secrets:/secrets \
		-v $DOCKER_BINDS_DIR/fileport:/fileport \
		-v $DOCKER_BINDS_DIR/runner:/util/runner/log \
		--network "$NETWORK_NAME" \
		-e "GEOSERVER_CONTAINER=${GEOSERVER_CONTAINER}" \
		-e "GEOSERVER_USER=${GEOSERVER_USER}" \
		-e "GEOSERVER_PASSWORD=${GEOSERVER_PASSWORD}" \
		"$@" \
		-d $IMAGE
fi
