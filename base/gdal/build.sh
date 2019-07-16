#!/bin/bash
set -ex

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"

repo=$(basename "$(pwd)")
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}"

echo; echo "Building ${image}"

HERE=$(dirname "$0")

mkdir -p conf
cp -r "${HERE}/../plugins" "conf"
docker image build -t "${image}" .
rm -rf "conf/plugins"
