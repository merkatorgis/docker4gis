#!/bin/bash

build_dir="${1}"
single="${2}"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"

repo=$(basename "$(pwd)")
container="${DOCKER_USER}-${repo}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}"

echo; echo "Building ${image}"
docker container rm -f "${container}" 2>/dev/null

pushd "${build_dir}"

echo 'FROM docker4gis/serve' > ./Dockerfile
if [ "${single}" != '--single' ]; then
    echo 'CMD [ "serve", "--listen", "80", "/build" ]' >> ./Dockerfile
fi
docker image build -t "${image}" .
rm ./Dockerfile

popd
