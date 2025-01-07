#!/bin/bash

DOCKER_REPO=$(basename "$(realpath "$(dirname "$0")")")
IMAGE=docker4gis/$DOCKER_REPO
CONTAINER=docker4gis-$DOCKER_REPO

# FIXME: properly `dg push` this image (from the pipeline).
docker image build -t "$IMAGE" "$(dirname "$0")"

ENV_FILE=$HOME/.$CONTAINER.env
touch "$ENV_FILE"
chown "$USER" "$ENV_FILE"
chmod 600 "$ENV_FILE"

docker_socket=/var/run/docker.sock

# Tee all stdout & stderr to a log file (from
# https://superuser.com/a/212436/462952).
exec > >(tee devops.log) 2>&1

# We don't use the --env-file Docker option because it's tricky writing a value
# with spaces back to the file, and then getting it read back in correctly on
# the next container start.
docker container run --name "$CONTAINER" \
	--rm \
	--privileged \
	-ti \
	--env DOCKER_USER="$DOCKER_USER" \
	--env DEVOPS_ORGANISATION="$DEVOPS_ORGANISATION" \
	--env DEVOPS_DOCKER_REGISTRY="$DEVOPS_DOCKER_REGISTRY" \
	--env DEVOPS_VPN_POOL="$DEVOPS_VPN_POOL" \
	--mount type=bind,source="$ENV_FILE",target=/devops/env_file \
	--mount type=bind,source="$docker_socket",target="$docker_socket" \
	"$IMAGE" "$@"
