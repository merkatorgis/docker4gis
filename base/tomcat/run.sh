#!/bin/bash
set -e

if [ $1 ]
then
	TOMCAT_PORT="$1"
	shift 1
else
	TOMCAT_PORT="${TOMCAT_PORT}"
fi

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

docker volume create "${container}"
docker container run \
	--name $container \
	-e DOCKER_ENV=$DOCKER_ENV \
	--mount source="${container}",target=/host \
	-v $DOCKER_BINDS_DIR/fileport:/fileport \
	-v $DOCKER_BINDS_DIR/secrets:/secrets \
	-v $DOCKER_BINDS_DIR/runner:/util/runner/log \
	--network "${DOCKER_USER}-net" \
	$(.run/port.sh "${TOMCAT_PORT}" 8080) \
	"$@" \
	-d $image
