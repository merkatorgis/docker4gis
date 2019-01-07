#!/bin/bash
set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkator}"
DOCKER_REPO="${DOCKER_REPO:-serve}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
CONTAINER="${CONTAINER:-$DOCKER_USER-$DOCKER_REPO}"
NETWORK_NAME="${NETWORK_NAME:-$DOCKER_USER-net}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Running $CONTAINER from $IMAGE"
HERE=$(dirname "$0")
if ("$HERE/../rename.sh" "$IMAGE" "$CONTAINER"); then
	"$HERE/../network.sh"
	docker run --name $CONTAINER \
		--network "$NETWORK_NAME" \
		-p 5000:5000 \
		"$@" \
		-d $IMAGE
fi
