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

app_port=$(.run/port.sh "${app_port:-9090}")
admin_port=$(.run/port.sh "${admin_port:-5858}")

if .run/start.sh "${image}" "${container}"; then exit; fi

docker volume create "${container}"
docker container run --name "${container}" \
	-e DOCKER_USER="${DOCKER_USER}" \
	--network "${DOCKER_USER}" \
	--mount source="${container}",target=/host \
	-v "$(docker_bind_source "${DOCKER_BINDS_DIR}/fileport")":/fileport \
	-p "${app_port}":8080 \
	-p "${admin_port}":4848 \
	"$@" \
	-d "${image}"
