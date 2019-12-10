#!/bin/bash
set -e

if [ $1 ]
then
	MAPPROXY_PORT="$1"
	shift 1
else
	MAPPROXY_PORT="${MAPPROXY_PORT}"
fi

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER}"
DOCKER_TAG="${DOCKER_TAG}"
DOCKER_ENV="${DOCKER_ENV}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR}"

repo=$(basename "$0")
container="${DOCKER_USER}-${repo}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}:${DOCKER_TAG}"

if .run/start.sh "${image}" "${container}"; then exit; fi

docker run --name "${container}" \
	--network "${DOCKER_USER}-net" \
	$(.run/port.sh "${MAPPROXY_PORT}" 80) \
	"$@" \
	-d "${image}"
