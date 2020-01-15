#!/bin/bash
set -e

app_port="${1:-9090}"
admin_port="${2:-5858}"
shift 2

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER}"
DOCKER_TAG="${DOCKER_TAG}"
DOCKER_ENV="${DOCKER_ENV}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR}"

repo=$(basename "$0")
container="${DOCKER_USER}-${repo}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}:${DOCKER_TAG}"

if .run/start.sh "${image}" "${container}"; then exit; fi

docker volume create "${container}"
docker run --name "${container}" \
	--network "${DOCKER_USER}-net" \
	--mount source="${container}",target=/host \
	-v $DOCKER_BINDS_DIR/fileport:/fileport \
	$(.run/port.sh "${app_port}" 8080) \
	$(.run/port.sh "${admin_port}" 4848) \
	"$@" \
	-d "${image}"
