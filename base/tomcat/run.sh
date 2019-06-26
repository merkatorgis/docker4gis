#!/bin/bash
set -e

if [ $1 ]
then
	TOMCAT_PORT="$1"
	shift 1
else
	TOMCAT_PORT="${TOMCAT_PORT}"
fi

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-api}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR}"
DOCKER_ENV="${DOCKER_ENV}"
NETWORK_NAME="${NETWORK_NAME:-$DOCKER_USER-net}"

container="${TOMCAT_CONTAINER:-$DOCKER_USER-api}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"
here=$(dirname "$0")

if "$here/../start.sh" "${image}" "${container}"; then exit; fi

mkdir -p "${DOCKER_BINDS_DIR}/fileport"
mkdir -p "${DOCKER_BINDS_DIR}/secrets"
mkdir -p "${DOCKER_BINDS_DIR}/runner"

"$here/../network.sh"
docker container run \
	--name $container \
	-e DOCKER_ENV=$DOCKER_ENV \
	-v $DOCKER_BINDS_DIR/fileport:/fileport \
	-v $DOCKER_BINDS_DIR/secrets:/secrets \
	-v $DOCKER_BINDS_DIR/runner:/util/runner/log \
	--network "$NETWORK_NAME" \
	$("$here/../port.sh" "${TOMCAT_PORT}" 8080) \
	"$@" \
	-d $image
