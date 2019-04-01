#!/bin/bash
set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-app}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
NETWORK_NAME="${NETWORK_NAME:-$DOCKER_USER-net}"

container="${APP_CONTAINER:-$DOCKER_USER-app}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"
here=$(dirname "$0")

if "$here/../start.sh" "${container}"; then exit; fi

"$here/../network.sh"
docker container run --name $container \
	--network "$NETWORK_NAME" \
	"$@" \
	-d $image
