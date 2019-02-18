#!/bin/bash
set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-geoserver}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
CONTAINER="${GEOSERVER_CONTAINER:-$DOCKER_USER-gs}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

HERE=$(dirname "$0")
"$HERE/../rename.sh" "$IMAGE" "$CONTAINER" force

mkdir -p conf
cp -r "${HERE}/../plugins" "conf"
docker image build -t "${IMAGE}" .
rm -rf "conf/plugins"
