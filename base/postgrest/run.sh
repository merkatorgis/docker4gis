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

proxy="${PROXY_HOST}"
if [ "${PROXY_PORT}" ]
then
	proxy="${proxy}:${PROXY_PORT}"
fi
PGRST_SERVER_PROXY_URI="${PGRST_SERVER_PROXY_URI:-https://${proxy}/${DOCKER_USER}/api}"

docker container run --name "${container}" \
	-e DOCKER_USER="${DOCKER_USER}" \
	--network "${DOCKER_USER}" \
	-e PGRST_DB_URI="postgresql://web_authenticator:postgrest@${DOCKER_USER}-postgis/${DOCKER_USER}" \
	-e PGRST_DB_SCHEMA="${DOCKER_USER}" \
	-e PGRST_JWT_SECRET="${PGRST_JWT_SECRET}" \
    -e PGRST_PRE_REQUEST="public.pre_request" \
    -e PGRST_DB_ANON_ROLE="web_anon" \
    -e PGRST_SERVER_PROXY_URI="${PGRST_SERVER_PROXY_URI}" \
	-e PGRST_SERVER_PORT="8080" \
	"$@" \
	-d "${image}"
