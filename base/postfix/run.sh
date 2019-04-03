#!/bin/bash
set -e

POSTFIX_PORT="${POSTFIX_PORT:-25}"
POSTFIX_DESTINATION="${POSTFIX_DESTINATION}"
DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-postfix}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR}"
NETWORK_NAME="${NETWORK_NAME:-$DOCKER_USER-net}"

container="${POSTFIX_CONTAINER:-$DOCKER_USER-pf}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"
here=$(dirname "$0")

if "$here/../start.sh" "${container}"; then exit; fi

mkdir -p "${DOCKER_BINDS_DIR}/fileport"
mkdir -p "${DOCKER_BINDS_DIR}/runner"

destination=
if [ "${POSTFIX_DESTINATION}" != '' ]; then
	destination="-e DESTINATION=${POSTFIX_DESTINATION}"
fi

"$here/../network.sh"
docker run --name $container \
	-v $DOCKER_BINDS_DIR/fileport:/fileport \
	-v $DOCKER_BINDS_DIR/runner:/util/runner/log \
	-p $POSTFIX_PORT:25 \
		${destination} \
	--network "${NETWORK_NAME}" \
	-d $image
