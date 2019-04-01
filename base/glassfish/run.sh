#!/bin/bash
set -e

app_port="${1:-8080}"
admin_port="${2:-4848}"
shift 2

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-api}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
NETWORK_NAME="${NETWORK_NAME:-$DOCKER_USER-net}"

container="${GLASSFISH_CONTAINER:-$DOCKER_USER-$DOCKER_REPO}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"
here=$(dirname "$0")

if "$here/../start.sh" "${container}"; then exit; fi

"$here/../network.sh"
docker volume create "${container}"
docker run --name $container \
	--network "$NETWORK_NAME" \
	--mount source="${container}",target=/host \
	-p "${app_port}":8080 \
	-p "${admin_port}":4848 \
	"$@" \
	-d $image
