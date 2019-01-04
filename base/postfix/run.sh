#!/bin/bash
set -e

POSTFIX_PORT="${POSTFIX_PORT:-25}"
DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkator}"
DOCKER_REPO="${DOCKER_REPO:-postfix}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR:-d:/Docker/binds}"
POSTFIX_CONTAINER="${POSTFIX_CONTAINER:-$DOCKER_USER-pf}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

mkdir -p "${DOCKER_BINDS_DIR}/fileport"
mkdir -p "${DOCKER_BINDS_DIR}/runner"

echo; echo "Running $POSTFIX_CONTAINER from $IMAGE"
HERE=$(dirname "$0")
if ("$HERE/../rename.sh" "$IMAGE" "$POSTFIX_CONTAINER"); then
	docker run --name $POSTFIX_CONTAINER \
		-v $DOCKER_BINDS_DIR/fileport:/fileport \
		-v $DOCKER_BINDS_DIR/runner:/util/runner/log \
		-p $POSTFIX_PORT:25 \
		-d $IMAGE
fi
