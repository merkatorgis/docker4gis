#!/bin/bash

host_port=$1

if [ "$host_port" ]; then
	# if port is taken, increment until that port is free
	while ! docker container run --rm -p "$host_port":"$host_port" alpine true 1>/dev/null 2>&1; do
		host_port=$((host_port + 1))
	done
	echo "$host_port"
fi
