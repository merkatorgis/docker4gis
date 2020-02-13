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

if [ ! -f Dockerfile ]
then
    # Just to support old usages
    echo 'FROM docker4gis/serve' > Dockerfile
    if [ "${single}" = '--single' ]; then
        echo 'ENV SINGLE=--single' >> Dockerfile
    fi
fi

build() {
	docker image build -t "${image}" .
}

if [ -d "${build_dir}" ]
then
    cp Dockerfile "${build_dir}"
    pushd "${build_dir}"
        build
        rm Dockerfile
    popd
else
    build
fi
