#!/bin/bash
set -e

export PGHOST=${PGHOST:-$DOCKER_USER-postgis}
export PGPORT=${PGPORT:-5432}
export PGDATABASE=${PGDATABASE:-postgres}
export PGUSER=${PGUSER:-postgres}
export PGPASSWORD=${PGPASSWORD:-$PGUSER}

mkdir -p "$FILEPORT"
mkdir -p "$RUNNER"

docker container run --name "$DOCKER_CONTAINER" \
    --env-file "$ENV_FILE" \
    --env PGHOST="$PGHOST" \
    --env PGPORT="$PGPORT" \
    --env PGDATABASE="$PGDATABASE" \
    --env PGUSER="$PGUSER" \
    --env PGPASSWORD="$PGPASSWORD" \
    --env DOCKER_ENV="$DOCKER_ENV" \
    --mount type=bind,source="$FILEPORT",target=/fileport \
    --mount type=bind,source="$FILEPORT/..",target=/fileport/root \
    --mount type=bind,source="$RUNNER",target=/runner \
    --mount source="$DOCKER_VOLUME",target=/volume \
    --network "$DOCKER_NETWORK" \
    --rm "$DOCKER_IMAGE" postgis-ddl "$@"
