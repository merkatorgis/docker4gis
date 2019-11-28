#!/bin/bash
set -x #echo on

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER}"
DOCKER_TAG="${DOCKER_TAG}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR}"

repo=$(basename "$0")
container="${DOCKER_USER}-${repo}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}:${DOCKER_TAG}"
if .run/start.sh "${image}" "${container}"; then exit; fi

MAPPROXY_PORT="${MAPPROXY_PORT:-8081}"

# mkdir -p "${DOCKER_BINDS_DIR}/${repo}/cache"
# mkdir -p "${DOCKER_BINDS_DIR}/${repo}/config"

docker volume create "${container}"
docker run --name "${container}" \
	-p "${MAPPROXY_PORT}":8080 \
	"$@" \
	-d "${image}"
