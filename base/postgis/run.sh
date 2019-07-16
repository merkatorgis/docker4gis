#!/bin/bash

POSTGRES_USER="${1:-postgres}"
POSTGRES_PASSWORD="${2:-postgres}"
POSTGRES_DB="${3:-$DOCKER_USER}"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER}"
DOCKER_TAG="${DOCKER_TAG}"
DOCKER_ENV="${DOCKER_ENV}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR}"

repo=$(basename "$0")
container="${DOCKER_USER}-${repo}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}:${DOCKER_TAG}"

POSTGIS_PORT="${POSTGIS_PORT:-5432}"
PROXY_HOST="${PROXY_HOST:-localhost.merkator.com}"
PROXY_PORT="${PROXY_PORT:-8080}"
SECRET="${SECRET}"

if .run/start.sh "${image}" "${container}"; then exit; fi

mkdir -p "${DOCKER_BINDS_DIR}/secrets"
mkdir -p "${DOCKER_BINDS_DIR}/fileport"
mkdir -p "${DOCKER_BINDS_DIR}/runner"
mkdir -p "${DOCKER_BINDS_DIR}/certificates"

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
	--network "${DOCKER_USER}-net" \
	-d $image

sleep 1
# wait for db
docker container exec "$container" pg.sh -c "select" > /dev/null
