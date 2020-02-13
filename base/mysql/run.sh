#!/bin/bash

MYSQL_ROOT_PASSWORD="${1:-mysql}"
MYSQL_DATABASE="${2:-$DOCKER_USER}"

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

gateway=$(docker network inspect "${DOCKER_USER}" | grep 'Gateway' | grep -oP '\d+\.\d+\.\d+\.\d+')

MYSQL_PORT=$(.run/port.sh "${MYSQL_PORT:-3306}")

docker volume create "$container"
docker container run --name $container \
	-e DOCKER_USER="${DOCKER_USER}" \
	-e SECRET=$SECRET \
	-e DOCKER_ENV=$DOCKER_ENV \
	-e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
	-e MYSQL_DATABASE=$MYSQL_DATABASE \
	-e CONTAINER=$container \
	-e GATEWAY=$gateway \
	-v "$(docker_bind_source "${DOCKER_BINDS_DIR}/secrets")":/secrets \
	-v "$(docker_bind_source "${DOCKER_BINDS_DIR}/fileport")":/fileport \
	-v "$(docker_bind_source "${DOCKER_BINDS_DIR}/runner")":/util/runner/log \
	--mount source="$container",target=/var/lib/mysql \
	-p "${MYSQL_PORT}":3306 \
	--network "${DOCKER_USER}" \
	-d $image

# wait for db
docker container exec "$container" mysql.sh force "${MYSQL_DATABASE}" -e ""
