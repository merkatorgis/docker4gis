#!/bin/bash
set -e

POSTFIX_PORT=$(docker4gis/port.sh "${POSTFIX_PORT:-25}")

mkdir -p "$FILEPORT"
mkdir -p "$RUNNER"

docker container run --restart "$RESTART" --name "$DOCKER_CONTAINER" \
	--env-file "$ENV_FILE" \
	--mount type=bind,source="$FILEPORT",target=/fileport \
	--mount type=bind,source="$FILEPORT/..",target=/fileport/root \
	--mount type=bind,source="$RUNNER",target=/runner \
	--mount source="$DOCKER_VOLUME",target=/volume \
	--network "$DOCKER_NETWORK" \
	--publish "$POSTFIX_PORT":25 \
	--detach "$DOCKER_IMAGE" postfix "$@"
