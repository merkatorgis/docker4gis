#!/bin/bash

DOCKER_BASE=$(dirname "$0")/../base
DOCKER4GIS_VERSION=${DOCKER4GIS_VERSION:-$(node --print "require('$DOCKER_BASE/../package.json').version")}

DOCKER_USER=docker4gis
DOCKER_REPO=$(basename "$(realpath "$(dirname "$0")")")
CONTAINER=$DOCKER_USER-$DOCKER_REPO
IMAGE=$DOCKER_USER/$DOCKER_REPO:$DOCKER4GIS_VERSION

ENV_FILE=$HOME/.$CONTAINER.env
touch "$ENV_FILE"
chown "$USER" "$ENV_FILE"
chmod 600 "$ENV_FILE"

docker_socket=/var/run/docker.sock

docker container run --name "$CONTAINER" \
	--rm \
	--privileged \
	-ti \
	--env DEVOPS_ORGANISATION "$DEVOPS_ORGANISATION" \
	--env DEVOPS_DOCKER_REGISTRY "$DEVOPS_DOCKER_REGISTRY" \
	--env DEVOPS_VPN_POOL "$DEVOPS_VPN_POOL" \
	--env-file "$ENV_FILE" \
	--mount type=bind,source="$ENV_FILE",target=/devops/env_file \
	--mount type=bind,source="$docker_socket",target="$docker_socket" \
	"$IMAGE" "$@"
