#!/bin/bash

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkatorgis}"
DOCKER_REPO="${DOCKER_REPO:-postgis}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
CONTAINER="${POSTGIS_CONTAINER:-$DOCKER_USER-pg}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

HERE=$(dirname "$0")
"$HERE/../rename.sh" "$IMAGE" "$CONTAINER" force

mkdir -p conf
cp -r "${HERE}/../plugins" "conf"
sudo docker image build -t "${IMAGE}" .
rm -rf "conf/plugins"
