#!/bin/bash

src_dir="$1"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-api}"
DOCKER_TAG="${DOCKER_TAG:-latest}"

container="${DOCKER_CONTAINER:-$DOCKER_USER-api}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Compiling from '${src_dir}'..."

docker volume create mvndata

if docker container run --rm \
    -v "${src_dir}":/src \
    --mount source=mvndata,target=/root/.m2 \
    docker4gis/maven
then
    echo; echo "Building ${image}"
    docker container rm -f "${container}" 2>/dev/null

    mkdir -p conf
    here=$(dirname "$0")
    cp -r conf "${here}"

    pushd "${here}"
    mkdir -p conf/webapps
    app_name=$(basename "${src_dir}")
    cp "${src_dir}"/target/*.war "conf/webapps/${app_name}.war"

    docker image build -t "${image}" .
    rm -rf conf
    popd
fi
