#!/bin/bash
set -e

build_dir="${1}"
single="${2:---single}"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-app}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
SERVE_CONTAINER="${SERVE_CONTAINER:-$DOCKER_USER-app}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

HERE=$(dirname "$0")
"$HERE/../rename.sh" "$IMAGE" "$SERVE_CONTAINER" force

pushd "${build_dir}"

echo 'FROM docker4gis/serve' > ./Dockerfile
if [ "${single}" != '--single' ]; then
    echo 'CMD [ "serve", "--listen", "80", "/build" ]' >> ./Dockerfile
fi
docker image build -t "${IMAGE}" .
rm ./Dockerfile

popd
