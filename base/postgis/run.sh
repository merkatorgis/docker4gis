#!/bin/bash

POSTGIS_PORT="${POSTGIS_PORT:-5432}"
PROXY_HOST="${PROXY_HOST:-localhost.merkator.com}"
PROXY_PORT="${PROXY_PORT:-8080}"
SECRET="${SECRET}"
DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkator}"
DOCKER_REPO="${DOCKER_REPO:-postgis}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
POSTGRES_USER="${1:-postgres}"
POSTGRES_PASSWORD="${2:-postgres}"
POSTGRES_DB="${3:-$DOCKER_USER}"
CONTAINER="${POSTGIS_CONTAINER:-$DOCKER_USER-pg}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR:-d:/Docker/binds}"
NETWORK_NAME="${NETWORK_NAME:-$DOCKER_USER-net}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

mkdir -p "${DOCKER_BINDS_DIR}/secrets"
mkdir -p "${DOCKER_BINDS_DIR}/fileport"
mkdir -p "${DOCKER_BINDS_DIR}/runner"
mkdir -p "${DOCKER_BINDS_DIR}/certificates"

echo; echo "Running $CONTAINER from $IMAGE"
HERE=$(dirname "$0")
if ("$HERE/../rename.sh" "$IMAGE" "$CONTAINER"); then
	"$HERE/../network.sh"
	docker volume create pgdata
	docker run --name $CONTAINER \
		-e PROXY=https://$PROXY_HOST:$PROXY_PORT \
		-e SECRET=$SECRET \
		-e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
		-e POSTGRES_DB=$POSTGRES_DB \
		-e POSTGRES_USER=$POSTGRES_USER \
		-e POSTGIS_HOST=$POSTGIS_HOST \
		-e CONTAINER=$CONTAINER \
		-v $DOCKER_BINDS_DIR/secrets:/secrets \
		-v $DOCKER_BINDS_DIR/certificates:/certificates \
		-v $DOCKER_BINDS_DIR/fileport:/fileport \
		-v $DOCKER_BINDS_DIR/runner:/util/runner/log \
		--mount source=pgdata,target=/var/lib/postgresql/data \
		-p $POSTGIS_PORT:5432 \
		--network "$NETWORK_NAME" \
		-d $IMAGE
fi

sleep 1
# wait for db
docker exec "$CONTAINER" pg.sh -c 'select 1' > /dev/null
