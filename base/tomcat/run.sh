#!/bin/bash
set -e

repo="$1"
tag="$2"
shift 2

DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="$DOCKER_USER"
DOCKER_ENV="$DOCKER_ENV"
DOCKER_BINDS_DIR="$DOCKER_BINDS_DIR"

container="$DOCKER_USER"-"$repo"
image="$DOCKER_REGISTRY""$DOCKER_USER"/"$repo":"$tag"

XMS="${XMS:-256m}"
XMX="${XMX:-2g}"

TOMCAT_PORT=$(base/port.sh "${TOMCAT_PORT:-9090}")

docker volume create "$container" >/dev/null
docker container run --restart always --name "$container" \
	-e DOCKER_USER="$DOCKER_USER" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-e XMS="$XMS" \
	-e XMX="$XMX" \
	--mount source="$container",target=/host \
	-v "$(docker_bind_source "$DOCKER_BINDS_DIR"/secrets)":/secrets \
	-v "$(docker_bind_source "$DOCKER_BINDS_DIR"/fileport)":/fileport \
	-v "$(docker_bind_source "$DOCKER_BINDS_DIR"/runner)":/util/runner/log \
	--network "$DOCKER_USER" \
	-p "$TOMCAT_PORT":8080 \
	"$@" \
	-d "$image"
