#!/bin/bash
set -e

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART
IP=$IP
FILEPORT=$FILEPORT
RUNNER=$RUNNER

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

gateway=$(docker network inspect "$DOCKER_USER" | grep 'Gateway' | grep -oP '\d+\.\d+\.\d+\.\d+')

MYSQL_PORT=$(docker4gis/port.sh "${MYSQL_PORT:-3306}")

docker volume create "$CONTAINER" >/dev/null
docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_USER="$DOCKER_USER" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-e CONTAINER="$CONTAINER" \
	-e GATEWAY="$gateway" \
	--mount type=bind,source="$FILEPORT",target=/fileport \
	--mount type=bind,source="$RUNNER",target=/runner \
	--mount source="$CONTAINER",target=/var/lib/mysql \
	-p "$MYSQL_PORT":3306 \
	--network "$DOCKER_USER" \
	--ip "$IP" \
	-d "$IMAGE"

# wait for db
docker container exec "$CONTAINER" mysql.sh force "$MYSQL_DATABASE" -e ""
