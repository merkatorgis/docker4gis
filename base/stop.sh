#!/bin/bash

DOCKER_USER="${DOCKER_USER}"

main=$(dirname "$1")

for file in "${main}"/*; do
    if [ -d "${file}" ]; then
        repo=$(basename "${file}")
        if [ "$repo" != 'proxy' ] && [ "$repo" != 'test' ] && [ "$repo" != '.package' ]; then
            container="${DOCKER_USER}-${repo}"
            echo "Stopping ${container}..."
            docker stop "${container}"
        fi
    fi
done
