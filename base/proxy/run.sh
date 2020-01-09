#!/bin/bash
set -e

PROXY_HOST="${PROXY_HOST:-localhost}"
PROXY_PORT="${PROXY_PORT:-443}"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER}"
DOCKER_TAG="${DOCKER_TAG}"
DOCKER_ENV="${DOCKER_ENV}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR}"

repo=$(basename "$0")
container="${DOCKER_USER}-${repo}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}:${DOCKER_TAG}"

API_CONTAINER="${API_CONTAINER:-$DOCKER_USER-api}"
APP_CONTAINER="${APP_CONTAINER:-$DOCKER_USER-app}"
RESOURCES_CONTAINER="${RESOURCES_CONTAINER:-$DOCKER_USER-resources}"
GEOSERVER_CONTAINER="${GEOSERVER_CONTAINER:-$DOCKER_USER-geoserver}"
MAPFISH_CONTAINER="${MAPFISH_CONTAINER:-$DOCKER_USER-mapfish}"

API="${API:-http://${API_CONTAINER}:8080/}"
APP="${APP:-http://${APP_CONTAINER}/}"
RESOURCES="${RESOURCES:-http://${RESOURCES_CONTAINER}/}"
HOMEDEST="${HOMEDEST}"
NGR="${NGR:-https://geodata.nationaalgeoregister.nl}"
GEOSERVER="${GEOSERVER:-http://${GEOSERVER_CONTAINER}:8080/geoserver/}"
MAPFISH="${MAPFISH:-http://${MAPFISH_CONTAINER}:8080/}"
SECRET="${SECRET}"

if .run/start.sh "${image}" "${container}"; then exit; fi

mkdir -p "${DOCKER_BINDS_DIR}/certificates"

getip()
{
	if result=$(getent ahostsv4 "${1}" 2>/dev/null); then
		echo "${result}" | awk '{ print $1 ; exit }'
	elif result=$(ping -4 -n 1 "${1}" 2>/dev/null); then
		echo "${result}" | grep "${1}" | sed 's~.*\[\(.*\)\].*~\1~'
		# Pinging wouter [10.0.75.1] with 32 bytes of data:
	elif result=$(ping -c 1 "${1}" 2>/dev/null); then
		echo "${result}" | grep PING | grep -o -E '\d+\.\d+\.\d+\.\d+'
		# PING macbook-pro-van-wouter.local (188.166.80.233): 56 data bytes
	else
		echo '127.0.0.1'
	fi
}

urlhost()
{
	echo "${1}" | sed 's~.*//\([^:/]*\).*~\1~'
}

docker run --name $container \
	-e PROXY_HOST=$PROXY_HOST \
	-e API=$API \
	-e APP=$APP \
	-e RESOURCES=$RESOURCES \
	-e HOMEDEST=$HOMEDEST \
	-e NGR=$NGR \
	-e GEOSERVER=$GEOSERVER \
	-e MAPFISH=$MAPFISH \
	-e SECRET=$SECRET \
	-v $DOCKER_BINDS_DIR/certificates:/certificates \
	-p $PROXY_PORT:443 \
	--network "${DOCKER_USER}-net" \
	--add-host=$(hostname):$(getip $(hostname)) \
	--add-host="${PROXY_HOST}":$(getip $(urlhost "${API}")) \
	-d $image proxy "$@"
