#!/bin/bash

net="${1:-${DOCKER_USER}}"

if docker network create "${net}" 1>/dev/null 2>&1; then
	echo Created network "${net}"
fi
