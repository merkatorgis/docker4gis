#!/bin/bash
set -e

PROXY_HOST="${PROXY_HOST:-localhost}"
PROXY_PORT="${PROXY_PORT:-443}"
DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-proxy}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR:-d:/Docker/binds}"
NETWORK_NAME="${NETWORK_NAME:-$DOCKER_USER-net}"

API_CONTAINER="${API_CONTAINER:-$DOCKER_USER-api}"
APP_CONTAINER="${APP_CONTAINER:-$DOCKER_USER-app}"
RESOURCES_CONTAINER="${RESOURCES_CONTAINER:-$DOCKER_USER-res}"
GEOSERVER_CONTAINER="${GEOSERVER_CONTAINER:-$DOCKER_USER-gs}"
MAPFISH_CONTAINER="${MAPFISH_CONTAINER:-$DOCKER_USER-mf}"
API="${API:-http://${API_CONTAINER}:8080/}"
APP="${APP:-http://${APP_CONTAINER}/}"
RESOURCES="${RESOURCES:-http://${RESOURCES_CONTAINER}/}"
HOMEDEST="${HOMEDEST}"
NGR="${NGR:-https://geodata.nationaalgeoregister.nl}"
GEOSERVER="${GEOSERVER:-http://${GEOSERVER_CONTAINER}:8080/geoserver/}"
MAPFISH="${MAPFISH:-http://${MAPFISH_CONTAINER}:8080/}"
SECRET="${SECRET}"

container="${PROXY_CONTAINER:-$DOCKER_USER-px}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"
here=$(dirname "$0")

if "$here/../start.sh" "${container}"; then exit; fi

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

"$here/../network.sh"
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
	--network "$NETWORK_NAME" \
	--add-host=$(hostname):$(getip $(hostname)) \
	--add-host="${PROXY_HOST}":$(getip $(urlhost "${API}")) \
	-d $image proxy "$@"
