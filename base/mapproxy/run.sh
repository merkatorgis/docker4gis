#!/bin/bash
set -e

MAPPROXY_PORT="${MAPPROXY_PORT:-58081}"

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
	--network "${DOCKER_USER}" \
	$(.run/port.sh "${MAPPROXY_PORT}" 80) \
	"$@" \
	-d "${image}"
