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

docker container run --name "$CONTAINER" \
	--rm \
	-ti \
	--env-file "$ENV_FILE" \
	--mount type=bind,source="$ENV_FILE",target=/env_file \
	"$IMAGE" "$@"
