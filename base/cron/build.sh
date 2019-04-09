#!/bin/bash

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-cron}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
CRON_CONTAINER="${CRON_CONTAINER:-$DOCKER_USER-cr}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"
docker container rm -f "${CRON_CONTAINER}" 2>/dev/null

HERE=$(dirname "$0")

mkdir -p conf
cp -r "${HERE}/../plugins" "conf"
docker image build -t "${IMAGE}" .
rm -rf "conf/plugins"
