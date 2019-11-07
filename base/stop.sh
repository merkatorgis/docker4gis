#!/bin/bash

DOCKER_USER="${DOCKER_USER}"

main=$(dirname "$1")

for file in "${main}"/*
do
    if [ -d "${file}" ]
    then
        repo=$(basename "${file}")
        container="${DOCKER_USER}-${repo}"
        echo "Stopping ${container}..."

        set +e
        docker stop "${container}" 2>/dev/null
        set -e
    fi
done
