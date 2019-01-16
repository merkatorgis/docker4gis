#!/bin/bash
set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkatorgis}"
DOCKER_REPO="${DOCKER_REPO:-mapfish}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
MAPFISH_CONTAINER="${MAPFISH_CONTAINER:-$DOCKER_USER-mf}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

HERE=$(dirname "$0")
"$HERE/../rename.sh" "$IMAGE" "$MAPFISH_CONTAINER" force

mkdir -p conf
cp -r "${HERE}/../plugins" "conf"
docker image build -t "${IMAGE}" .
rm -rf "conf/plugins"
