#!/usr/bin/bash
set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkatorgis}"
DOCKER_REPO="${DOCKER_REPO:-geoserver}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
CONTAINER="${GEOSERVER_CONTAINER:-$DOCKER_USER-gs}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

HERE=$(dirname "$0")
"$HERE/../rename.sh" "$IMAGE" "$CONTAINER" force

cp -r "$HERE/../include" "$HERE/conf"
docker build -t $IMAGE .
rm -rf "$HERE/conf/include"
