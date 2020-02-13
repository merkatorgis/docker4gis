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

GEOSERVER_CONTAINER="${GEOSERVER_CONTAINER:-${DOCKER_USER}-geoserver}"
GEOSERVER_USER="${GEOSERVER_USER:-admin}"
GEOSERVER_PASSWORD="${GEOSERVER_PASSWORD:-geoserver}"

if .run/start.sh "${image}" "${container}"; then exit; fi

docker container run --name $container \
	-e DOCKER_USER="${DOCKER_USER}" \
	-v "$(docker_bind_source "${DOCKER_BINDS_DIR}/secrets")":/secrets \
	-v "$(docker_bind_source "${DOCKER_BINDS_DIR}/fileport")":/fileport \
	-v "$(docker_bind_source "${DOCKER_BINDS_DIR}/runner")":/util/runner/log \
	--network "${DOCKER_USER}" \
	-e "GEOSERVER_CONTAINER=${GEOSERVER_CONTAINER}" \
	-e "GEOSERVER_USER=${GEOSERVER_USER}" \
	-e "GEOSERVER_PASSWORD=${GEOSERVER_PASSWORD}" \
	"$@" \
	-d $image
