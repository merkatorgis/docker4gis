#!/bin/bash

image="$1"
container="$2"

echo; echo "Starting $container..."

if container_ls=$(docker container ls -a | grep "${container}$"); then
	old_image=$(echo "${container_ls}" | sed -n -e 's|\w*\s*\(\S*\).*|\1|p')
	if [ "${old_image}" != "${image}" ]; then
		docker container rm -f "${container}" 2>/dev/null
        exit 1
	fi
fi

docker container start "${container}" 2>/dev/null
