#!/bin/bash
set -e

PROXY_HOST="${PROXY_HOST:-localhost}"
PROXY_PORT="${PROXY_PORT:-443}"
DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkator}"
DOCKER_REPO="${DOCKER_REPO:-proxy}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR:-d:/Docker/binds}"
CONTAINER="${PROXY_CONTAINER:-$DOCKER_USER-px}"
NETWORK_NAME="${NETWORK_NAME:-$DOCKER_USER-net}"

API_CONTAINER="${API_CONTAINER:-$DOCKER_USER-api}"
APP_CONTAINER="${APP_CONTAINER:-$DOCKER_USER-app}"
GEOSERVER_CONTAINER="${GEOSERVER_CONTAINER:-$DOCKER_USER-gs}"
MAPFISH_CONTAINER="${MAPFISH_CONTAINER:-$DOCKER_USER-mf}"
API="${API:-http://${API_CONTAINER}/}"
APP="${APP:-http://${APP_CONTAINER}/}"
HOMEDEST="${HOMEDEST}"
NGR="${NGR:-https://geodata.nationaalgeoregister.nl}"
GEOSERVER="${GEOSERVER:-https://${GEOSERVER_CONTAINER}/geoserver/}"
MAPFISH="${MAPFISH:-http://${MAPFISH_CONTAINER}:8080/}"
SECRET="${SECRET}"

getip()
{
	if which getent >/dev/null 2>&1; then
		if result=$(getent ahostsv4 "${1}"); then
			echo "${result}" | awk '{ print $1 ; exit }'
		else
			echo '127.0.0.1'
		fi
	else
		if result=$(ping -4 -n 1 "${1}"); then
			echo "${result}" | grep "${1}" | sed 's~.*\[\(.*\)\].*~\1~'
		else
			echo '127.0.0.1'
		fi
		# Pinging wouter [10.0.75.1] with 32 bytes of data:
	fi
}

urlhost()
{
	echo "${1}" | sed 's~.*//\([^:/]*\).*~\1~'
}

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

mkdir -p "${DOCKER_BINDS_DIR}/certificates"

echo; echo "Running $CONTAINER from $IMAGE"
HERE=$(dirname "$0")
if ("$HERE/../rename.sh" "$IMAGE" "$CONTAINER"); then
	"$HERE/../network.sh"
	docker run --name $CONTAINER \
		-e PROXY_HOST=$PROXY_HOST \
		-e API=$API \
		-e APP=$APP \
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
		-d $IMAGE proxy "$@"
fi
