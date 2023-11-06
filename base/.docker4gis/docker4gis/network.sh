#!/bin/bash

network=${1:-$DOCKER_USER}

docker network create "$network" 1>/dev/null 2>&1 &&
	echo "Network created: $network"

exit 0
