#!/bin/bash

POSTGIS_PORT="${POSTGIS_PORT:-5432}"
PROXY_HOST="${PROXY_HOST:-localhost.merkator.com}"
PROXY_PORT="${PROXY_PORT:-8080}"
SECRET="${SECRET}"
DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-postgis}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
DOCKER_ENV="${DOCKER_ENV}"

POSTGRES_USER="${1:-postgres}"
POSTGRES_PASSWORD="${2:-postgres}"
POSTGRES_DB="${3:-$DOCKER_USER}"

container="${POSTGIS_CONTAINER:-$DOCKER_USER-pg}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"
here=$(dirname "$0")

if "$here/../start.sh" "${container}"; then exit; fi

mkdir -p "${DOCKER_BINDS_DIR}/secrets"
mkdir -p "${DOCKER_BINDS_DIR}/fileport"
mkdir -p "${DOCKER_BINDS_DIR}/runner"
mkdir -p "${DOCKER_BINDS_DIR}/certificates"

"$here/../network.sh"
docker volume create "$container"
docker run --name $container \
	-e PROXY=https://$PROXY_HOST:$PROXY_PORT \
	-e SECRET=$SECRET \
	-e DOCKER_ENV=$DOCKER_ENV \
	-e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
	-e POSTGRES_DB=$POSTGRES_DB \
	-e POSTGRES_USER=$POSTGRES_USER \
	-e POSTGIS_HOST=$POSTGIS_HOST \
	-e CONTAINER=$container \
	-v $DOCKER_BINDS_DIR/secrets:/secrets \
	-v $DOCKER_BINDS_DIR/certificates:/certificates \
	-v $DOCKER_BINDS_DIR/fileport:/fileport \
	-v $DOCKER_BINDS_DIR/runner:/util/runner/log \
	--mount source="$container",target=/var/lib/postgresql/data \
	-p $POSTGIS_PORT:5432 \
	--network "$NETWORK_NAME" \
	-d $image

sleep 1
# wait for db
# docker exec "$container" pg.sh -c 'select 1' > /dev/null
