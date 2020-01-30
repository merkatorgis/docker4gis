#!/bin/bash
set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER}"
DOCKER_TAG="${DOCKER_TAG}"
DOCKER_ENV="${DOCKER_ENV}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR}"

repo=$(basename "$0")
container="${DOCKER_USER}-${repo}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}:${DOCKER_TAG}"

if .run/start.sh "${image}" "${container}"; then exit; fi

mkdir -p "${DOCKER_BINDS_DIR}/fileport"
mkdir -p "${DOCKER_BINDS_DIR}/secrets"
mkdir -p "${DOCKER_BINDS_DIR}/runner"

XMS="${XMS:-256m}"
XMX="${XMX:-2g}"

TOMCAT_PORT=$(.run/port.sh "${TOMCAT_PORT:-9090}")

docker volume create "${container}"
docker container run --name $container \
	-e DOCKER_USER="${DOCKER_USER}" \
	-e DOCKER_ENV=$DOCKER_ENV \
	-e XMS="${XMS}" \
	-e XMX="${XMX}" \
	--mount source="${container}",target=/host \
	-v $DOCKER_BINDS_DIR/fileport:/fileport \
	-v $DOCKER_BINDS_DIR/secrets:/secrets \
	-v $DOCKER_BINDS_DIR/runner:/util/runner/log \
	--network "${DOCKER_USER}" \
	-p "${TOMCAT_PORT}":8080 \
	"$@" \
	-d $image
