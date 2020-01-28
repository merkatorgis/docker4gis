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

SECRET="${SECRET}"

if .run/start.sh "${image}" "${container}"; then exit; fi

mkdir -p "${DOCKER_BINDS_DIR}/secrets"
mkdir -p "${DOCKER_BINDS_DIR}/fileport"
mkdir -p "${DOCKER_BINDS_DIR}/runner"
mkdir -p "${DOCKER_BINDS_DIR}/certificates"

postfix_domain=
if [ "${POSTFIX_DOMAIN}" != '' ]; then
	postfix_domain="-e POSTFIX_DOMAIN=${POSTFIX_DOMAIN}"
fi

POSTGIS_PORT=$(.run/port.sh "${POSTGIS_PORT:-5432}")

docker volume create "$container"
docker container run --name $container \
	-e DOCKER_USER="${DOCKER_USER}" \
	-e SECRET=$SECRET \
	-e DOCKER_ENV=$DOCKER_ENV \
	${postfix_domain} \
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
	-p "${POSTGIS_PORT}":5432 \
	--network "${DOCKER_USER}" \
	-d $image

# wait for db
while [ ! $(docker container exec "$container" pg.sh -Atc "select current_setting('app.ddl_done', true)") = true ]
do
	sleep 1
done
