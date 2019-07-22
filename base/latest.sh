#!/bin/bash

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER}"

main_script="$1"

for file in $(dirname "${main_script}")/*
do
    if [ -d "${file}" ]
    then
        repo=$(basename "${file}")
        container="${DOCKER_USER}-${repo}"
        image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}:latest"

        docker container rm -f "${container}" 2>/dev/null
        docker image pull "${image}"
    fi
done

docker image pull "${DOCKER_REGISTRY}${DOCKER_USER}/package:latest"

"${main_script}" run
