#!/bin/bash
set -e

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

OSM_THREADS=${OSM_THREADS:-4}
OSM_CACHE_MB=${OSM_CACHE_MB:-800}

volume_db="$CONTAINER"-db
volume_tiles="$CONTAINER"-tiles
docker volume create "$volume_db" >/dev/null
docker volume create "$volume_tiles" >/dev/null

docker container run --restart "$RESTART" --name "$CONTAINER" \
	--network "$DOCKER_USER" \
	--mount source="$volume_db",target=/var/lib/postgresql/12/main \
	--mount source="$volume_tiles",target=/var/lib/mod_tile \
	-e THREADS="$OSM_THREADS" \
	-e OSM2PGSQL_EXTRA_ARGS="-C $OSM_CACHE_MB" \
	-d "$IMAGE"
