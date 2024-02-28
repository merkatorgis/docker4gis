#!/bin/bash
set -e

SHM_SIZE=${SHM_SIZE:-64m}
POSTGRES_LOG_STATEMENT=$POSTGRES_LOG_STATEMENT

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART
IP=$IP

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

SECRET=$SECRET

POSTGIS_PORT=$(docker4gis/port.sh "${POSTGIS_PORT:-5432}")

docker volume create "$CONTAINER" >/dev/null
docker container run --restart "$RESTART" --name "$CONTAINER" \
	--shm-size="$SHM_SIZE" \
	-e DOCKER_USER="$DOCKER_USER" \
	-e SECRET="$SECRET" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-e POSTGRES_LOG_STATEMENT="$POSTGRES_LOG_STATEMENT" \
	-e "$(docker4gis/noop.sh POSTFIX_DOMAIN "$POSTFIX_DOMAIN")" \
	-e CONTAINER="$CONTAINER" \
	--mount type=bind,source="$DOCKER_BINDS_DIR"/certificates,target=/certificates \
	--mount type=bind,source="$DOCKER_BINDS_DIR"/fileport,target=/fileport \
	--mount type=bind,source="$DOCKER_BINDS_DIR"/runner,target=/util/runner/log \
	--mount source="$CONTAINER",target=/var/lib/postgresql/data \
	-p "$POSTGIS_PORT":5432 \
	--network "$DOCKER_USER" \
	--ip "$IP" \
	-d "$IMAGE"

# wait until all DDL has run
sql="alter database $POSTGRES_DB set app.ddl_done to false"
docker container exec "$CONTAINER" pg.sh -c "$sql" >/dev/null 2>&1
while
	sql="select current_setting('app.ddl_done', true)"
	result=$(docker container exec "$CONTAINER" pg.sh -Atc "$sql")
	[ "$result" != "true" ]
do
	sleep 1
done
