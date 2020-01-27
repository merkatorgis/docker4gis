#!/bin/bash
set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER}"
DOCKER_TAG="${DOCKER_TAG}"
DOCKER_ENV="${DOCKER_ENV}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR}"

repo=$(basename "$0")
container="${DOCKER_USER}-${repo}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}:${DOCKER_TAG}"

POSTFIX_DESTINATION="${POSTFIX_DESTINATION}"

if .run/start.sh "${image}" "${container}"; then exit; fi

mkdir -p "${DOCKER_BINDS_DIR}/fileport"
mkdir -p "${DOCKER_BINDS_DIR}/runner"

destination=
if [ "${POSTFIX_DESTINATION}" != '' ]; then
	destination="-e DESTINATION=${POSTFIX_DESTINATION}"
fi

POSTFIX_PORT=$(.run/port.sh "${POSTFIX_PORT:-25}")

docker container run --name $container \
	-e DOCKER_USER="${DOCKER_USER}" \
	-v $DOCKER_BINDS_DIR/fileport:/fileport \
	-v $DOCKER_BINDS_DIR/runner:/util/runner/log \
	-p "${POSTFIX_PORT}":25 \
	${destination} \
	--network "${DOCKER_USER}" \
	-d $image
