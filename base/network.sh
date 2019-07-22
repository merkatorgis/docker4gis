#!/bin/bash

DOCKER_USER="${DOCKER_USER}"

net="${DOCKER_USER}-net"

if docker network create "${net}" 1>/dev/null 2>&1; then
	echo "${net}"
fi
