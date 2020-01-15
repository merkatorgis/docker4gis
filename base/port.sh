#!/bin/bash

host_port=$1
container_port=$2

if [ ${host_port} ]
then
	# If taken, increment port until it's free
	while ! docker container run --rm -p "${host_port}":"${host_port}" alpine true 1>/dev/null 2>&1
	do
		host_port=$((host_port + 1))
	done
	echo "-p ${host_port}:${container_port}"
fi
