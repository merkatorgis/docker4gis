#!/bin/bash
set -e

build_dir="${1}"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkatorgis}"
DOCKER_REPO="${DOCKER_REPO:-app}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
APP_CONTAINER="${APP_CONTAINER:-$DOCKER_USER-app}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

HERE=$(dirname "$0")
"$HERE/../rename.sh" "$IMAGE" "$APP_CONTAINER" force

pushd "${build_dir}"

echo 'FROM merkatorgis/serve' > ./Dockerfile
docker image build -t "${IMAGE}" .
rm ./Dockerfile

popd
