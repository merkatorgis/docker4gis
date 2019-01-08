#!/bin/bash
set -e

src_dir="${1}"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkatorgis}"
DOCKER_REPO="${DOCKER_REPO:-elm}"
DOCKER_TAG="${DOCKER_TAG:-latest}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

pushd "${src_dir}"
echo 'FROM merkatorgis/elm-app' > ./Dockerfile
docker image build -t elm-app/build .
rm ./Dockerfile
popd

mkdir -p build
docker container run \
    --rm \
    -v $PWD/build:/app/build \
    elm-app/build
docker image rm elm-app/build


here=$(dirname "$0")

"${here}/../serve/build.sh" "$(pwd)/build"

rm -rf build
