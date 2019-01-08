#!/bin/bash
set -e

app_port="${1:-8080}"
admin_port="${2:-4848}"
shift 2

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkatorgis}"
DOCKER_REPO="${DOCKER_REPO:-glassfish}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
CONTAINER="${CONTAINER:-$DOCKER_USER-$DOCKER_REPO}"
NETWORK_NAME="${NETWORK_NAME:-$DOCKER_USER-net}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Running $CONTAINER from $IMAGE"
HERE=$(dirname "$0")
if ("$HERE/../rename.sh" "$IMAGE" "$CONTAINER"); then
	"$HERE/../network.sh"
	docker volume create "${CONTAINER}"
	docker run --name $CONTAINER \
		--network "$NETWORK_NAME" \
		--mount source="${CONTAINER}",target=/host \
		-p "${app_port}":8080 \
		-p "${admin_port}":4848 \
		"$@" \
		-d $IMAGE
fi
