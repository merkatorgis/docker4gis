#!/bin/bash

src_dir="$1"
pushd "${src_dir}"
src_dir=$(pwd)
popd

maven_tag="${2:-latest}"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-api}"
DOCKER_TAG="${DOCKER_TAG:-latest}"

container="${DOCKER_CONTAINER:-$DOCKER_USER-api}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

here=$(dirname "$0")

if "${here}/../base/run.sh" "${src_dir}" "${maven_tag}"
then
    echo; echo "Building ${image}"
    docker container rm -f "${container}" 2>/dev/null

    app_name=$(basename "${src_dir}")
    war="conf/webapps/${app_name}.war"
    mkdir -p conf/webapps
    mv "${src_dir}"/target/*.war "${war}"

    docker image build -t "${image}" .

    mv "${war}" "${src_dir}"/target/
    if [ ! $(ls conf/webapps) ]
    then
        rm -rf conf/webapps
    fi
fi
