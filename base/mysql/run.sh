#!/bin/bash
set -e

repo=$1
tag=$2
shift 2

MYSQL_ROOT_PASSWORD=${1:-mysql}
MYSQL_DATABASE=${2:-$DOCKER_USER}

DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

SECRET=${SECRET}

container=$DOCKER_USER-$repo
image=$DOCKER_REGISTRY$DOCKER_USER/$repo:$tag

gateway=$(docker network inspect "$DOCKER_USER" | grep 'Gateway' | grep -oP '\d+\.\d+\.\d+\.\d+')

MYSQL_PORT=$(docker4gis/port.sh "${MYSQL_PORT:-3306}")

docker volume create "$container" >/dev/null
docker container run --restart always --name "$container" \
	-e DOCKER_USER="$DOCKER_USER" \
	-e SECRET="$SECRET" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
	-e MYSQL_DATABASE="$MYSQL_DATABASE" \
	-e CONTAINER="$container" \
	-e GATEWAY="$gateway" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR/secrets" /secrets)" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR/fileport" /fileport)" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR/runner" /util/runner/log)" \
	--mount source="$container",target=/var/lib/mysql \
	-p "$MYSQL_PORT":3306 \
	--network "$DOCKER_USER" \
	-d "$image"

# wait for db
docker container exec "$container" mysql.sh force "$MYSQL_DATABASE" -e ""
