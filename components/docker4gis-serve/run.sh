#!/bin/bash
set -e

mkdir -p "$FILEPORT"
mkdir -p "$RUNNER"

docker container run --restart "$RESTART" --name "$CONTAINER" \
	--env-file "$ENV_FILE" \
	--mount type=bind,source="$FILEPORT",target=/fileport \
	--mount type=bind,source="$FILEPORT/..",target=/fileport/root \
	--mount type=bind,source="$RUNNER",target=/runner \
	--mount source="$VOLUME",target=/volume \
	--network "$NETWORK" \
	--detach "$IMAGE" serve "$@"
