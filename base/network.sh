#!/bin/bash

net="${1:-$NETWORK_NAME}"

if sudo docker network create "${net}" 1>/dev/null 2>&1; then
	echo "${net}"
fi
