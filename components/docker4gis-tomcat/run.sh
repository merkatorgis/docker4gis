#!/bin/bash
set -e

XMS=${XMS:-256m}
XMX=${XMX:-2g}

TOMCAT_PORT=$(docker4gis/port.sh "${TOMCAT_PORT:-9090}")

mkdir -p "$FILEPORT"
mkdir -p "$RUNNER"

docker container run --restart "$RESTART" --name "$CONTAINER" \
	--env-file "$ENV_FILE" \
	--env XMS="$XMS" \
	--env XMX="$XMX" \
	--mount type=bind,source="$FILEPORT",target=/fileport \
	--mount type=bind,source="$FILEPORT/..",target=/fileport/root \
	--mount type=bind,source="$RUNNER",target=/runner \
	--mount source="$VOLUME",target=/host \
	--network "$NETWORK" \
	--publish "$TOMCAT_PORT":8080 \
	--detach "$IMAGE" tomcat "$@"
