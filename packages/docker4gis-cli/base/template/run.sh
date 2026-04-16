#!/bin/bash
set -e

mkdir -p "$FILEPORT"
mkdir -p "$RUNNER"

docker container run --restart "$RESTART" --name "$DOCKER_CONTAINER" \
	--env-file "$ENV_FILE" \
	--mount type=bind,source="$FILEPORT",target=/fileport \
	--mount type=bind,source="$FILEPORT/..",target=/fileport/root \
	--mount type=bind,source="$RUNNER",target=/runner \
	--mount source="$DOCKER_VOLUME",target=/volume \
	--network "$DOCKER_NETWORK" \
	--detach "$DOCKER_IMAGE" {{COMPONENT}} "$@"
