#!/bin/bash

push="${1}"
if [ "${push}" == '-push' ]; then
    shift 1
fi

tag="${1}"
image="${2}"

if [ "${image}" == 'run' ]; then
    echo 'To tag a run image, use the build action instead, eg:'
    echo 'APP_TAG=627 ./ex build run 38'
    echo 'Cancelling now, to preserve your run:latest image'
    exit 1
fi

image="${DOCKER_REGISTRY}${DOCKER_USER}/${image}"

docker image tag "${image}:latest" "${image}:${tag}"

if [ "${push}" == '-push' ]; then
    $(dirname "${0}")/push.sh "${@}"
fi
