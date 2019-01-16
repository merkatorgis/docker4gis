#!/bin/bash
set -e

build_dir="${1}"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkatorgis}"
DOCKER_REPO="${DOCKER_REPO:-app}"
DOCKER_TAG="${DOCKER_TAG:-latest}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

pushd "${build_dir}"

echo 'FROM merkatorgis/serve' > ./Dockerfile
docker image build -t "${IMAGE}" .
rm ./Dockerfile

popd
