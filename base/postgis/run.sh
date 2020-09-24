#!/bin/bash
set -e

repo="$1"
tag="$2"
shift 2

POSTGRES_USER="${1:-postgres}"
POSTGRES_PASSWORD="${2:-postgres}"
POSTGRES_DB="${3:-$DOCKER_USER}"

SHM_SIZE="${SHM_SIZE:-64m}"

DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="$DOCKER_USER"
DOCKER_ENV="${DOCKER_ENV:-DEVELOPMENT}"
DOCKER_BINDS_DIR="$DOCKER_BINDS_DIR"

container="$DOCKER_USER"-"$repo"
image="$DOCKER_REGISTRY""$DOCKER_USER"/"$repo":"$tag"

SECRET="$SECRET"

POSTGIS_PORT=$(docker4gis/port.sh "${POSTGIS_PORT:-5432}")

docker volume create "$container" >/dev/null
docker container run --restart always --name "$container" \
	--shm-size="$SHM_SIZE" \
	-e DOCKER_USER="$DOCKER_USER" \
	-e SECRET="$SECRET" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-e "$(docker4gis/noop.sh POSTFIX_DOMAIN "$POSTFIX_DOMAIN")" \
	-e POSTGRES_USER="$POSTGRES_USER" \
	-e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
	-e POSTGRES_DB="$POSTGRES_DB" \
	-e CONTAINER="$container" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/secrets /secrets)" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/certificates /certificates)" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/fileport /fileport)" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/runner /util/runner/log)" \
	--mount source="$container",target=/var/lib/postgresql/data \
	-p "$POSTGIS_PORT":5432 \
	--network "$DOCKER_USER" \
	-d "$image"

while
	sql="select current_setting('app.ddl_done', true)"
	result=$(docker container exec "$container" pg.sh -Atc "$sql")
	[ "$result" != "true" ]
do
	sleep 1
done
