#!/usr/bin/bash
set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkatorgis}"
DOCKER_REPO="${DOCKER_REPO:-cron}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
CRON_CONTAINER="${CRON_CONTAINER:-$DOCKER_USER-cr}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

HERE=$(dirname "$0")
"$HERE/../rename.sh" "$IMAGE" "$CRON_CONTAINER" force

cp -r "$HERE/../include" "$HERE/conf"
docker build -t $IMAGE .
rm -rf "$HERE/conf/include"
