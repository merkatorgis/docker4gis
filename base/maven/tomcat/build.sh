#!/bin/bash

src_dir="$1"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-api}"
DOCKER_TAG="${DOCKER_TAG:-latest}"

container="${DOCKER_CONTAINER:-$DOCKER_USER-api}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

here=$(dirname "$0")

if "${here}/../base/run.sh" "${src_dir}"
then
    echo; echo "Building ${image}"
    docker container rm -f "${container}" 2>/dev/null

    mkdir -p conf
    cp -r conf "${here}"

    pushd "${here}"
    mkdir -p conf/webapps
    app_name=$(basename "${src_dir}")
    cp "${src_dir}"/target/*.war "conf/webapps/${app_name}.war"

    docker image build -t "${image}" .
    rm -rf conf
    popd
fi
