#!/bin/bash
set -e

GEOSERVER_HOST="${GEOSERVER_HOST:-geoserver.merkator.com}"
DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-geoserver}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR:-d:/Docker/binds}"
CONTAINER="${GEOSERVER_CONTAINER:-$DOCKER_USER-gs}"
NETWORK_NAME="${NETWORK_NAME:-$DOCKER_USER-net}"
GEOSERVER_USER="${GEOSERVER_USER:-admin}"
GEOSERVER_PASSWORD="${GEOSERVER_PASSWORD:-geoserver}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

mkdir -p "${DOCKER_BINDS_DIR}/secrets"
mkdir -p "${DOCKER_BINDS_DIR}/fileport"
mkdir -p "${DOCKER_BINDS_DIR}/runner"
mkdir -p "${DOCKER_BINDS_DIR}/certificates"
mkdir -p "${DOCKER_BINDS_DIR}/gwc"

echo; echo "Running $CONTAINER from $IMAGE"
HERE=$(dirname "$0")
if ("$HERE/../rename.sh" "$IMAGE" "$CONTAINER"); then
	"$HERE/../network.sh"
	docker volume create gsdynamic
	docker run --name $CONTAINER \
		-e GEOSERVER_HOST=$GEOSERVER_HOST \
		-v $DOCKER_BINDS_DIR/secrets:/secrets \
		-v $DOCKER_BINDS_DIR/fileport:/fileport \
		-v $DOCKER_BINDS_DIR/certificates:/certificates \
		-v $DOCKER_BINDS_DIR/gwc:/geoserver/cache \
		-v $DOCKER_BINDS_DIR/runner:/util/runner/log \
		--mount source=gsdynamic,target=/geoserver/data/workspaces/dynamic \
		--network "$NETWORK_NAME" \
		-e "GEOSERVER_USER=${GEOSERVER_USER}" \
		-e "GEOSERVER_PASSWORD=${GEOSERVER_PASSWORD}" \
		"$@" \
		-d $IMAGE
fi
