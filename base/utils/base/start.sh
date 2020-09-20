#!/bin/bash

image="$1"
container="$2"

echo; echo "Starting $container..."

if container_ls=$(docker container ls -a | grep "${container}$")
then
	old_image=$(echo "${container_ls}" | awk '{print $2}')
	if [ "${old_image}" == "${image}" ]
	then
		if docker container start "${container}"
		then
			exit 0
		else 
			echo "Starting existing container failed; creating a new one..."
		fi
	fi
	docker container rm -f "${container}"
fi

exit 1
