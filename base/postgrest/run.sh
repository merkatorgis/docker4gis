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

PGRST_JWT_SECRET=$(docker container exec "${DOCKER_USER}-postgis" pg.sh force -Atc "select current_setting('app.jwt_secret')")

docker run --name "${container}" \
	--network "${DOCKER_USER}-net" \
	-e PGRST_DB_URI=postgresql://authenticator:postgrest@${DOCKER_USER}-postgis/${DOCKER_USER} \
	-e PGRST_DB_SCHEMA=${DOCKER_USER} \
	-e PGRST_JWT_SECRET=${PGRST_JWT_SECRET} \
	"$@" \
	-d "${image}"
