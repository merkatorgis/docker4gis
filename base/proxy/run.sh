#!/bin/bash
set -e

PROXY_HOST=${PROXY_HOST:-localhost}
PROXY_PORT=${PROXY_PORT:-443}
PROXY_PORT_HTTP=${PROXY_PORT_HTTP:-80}
AUTOCERT=${AUTOCERT:-false}

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR
DEBUG=${DEBUG:-false}

SECRET=$SECRET
API=$API
AUTH_PATH=$AUTH_PATH
APP=$APP
HOMEDEST=$HOMEDEST

mkdir -p "$DOCKER_BINDS_DIR"/certificates

getip() {
	if result=$(getent ahostsv4 "$1" 2>/dev/null); then
		echo "$result" | awk '{ print $1 ; exit }'
	elif result=$(ping -4 -n 1 "$1" 2>/dev/null); then
		echo "$result" | grep "$1" | sed 's~.*\[\(.*\)\].*~\1~'
		# Pinging wouter [10.0.75.1] with 32 bytes of data:
	elif result=$(ping -c 1 "${1}" 2>/dev/null); then
		echo "$result" | grep PING | grep -o -E '\d+\.\d+\.\d+\.\d+'
		# PING macbook-pro-van-wouter.local (188.166.80.233): 56 data bytes
	else
		echo '127.0.0.1'
	fi
}

urlhost() {
	echo "$1" | sed 's~.*//\([^:/]*\).*~\1~'
}

network=$CONTAINER
docker4gis/network.sh "$network"

volume=$CONTAINER
docker volume create "$volume" >/dev/null

PROXY_PORT=$(docker4gis/port.sh "$PROXY_PORT")
PROXY_PORT_HTTP=$(docker4gis/port.sh "$PROXY_PORT_HTTP")

docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e PROXY_HOST="$PROXY_HOST" \
	-e PROXY_PORT="$PROXY_PORT" \
	-e AUTOCERT="$AUTOCERT" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-e DEBUG="$DEBUG" \
	-e "$(docker4gis/noop.sh SECRET "$SECRET")" \
	-e "$(docker4gis/noop.sh API "$API")" \
	-e "$(docker4gis/noop.sh AUTH_PATH "$AUTH_PATH")" \
	-e "$(docker4gis/noop.sh APP "$APP")" \
	-e "$(docker4gis/noop.sh HOMEDEST "$HOMEDEST")" \
	-v "$(docker4gis/bind.sh "$DOCKER_BINDS_DIR"/certificates /certificates)" \
	--mount source="$volume",target=/config \
	-p "$PROXY_PORT":443 \
	-p "$PROXY_PORT_HTTP":80 \
	--network "$network" \
	--add-host="$(hostname)":"$(getip "$(hostname)")" \
	-d "$IMAGE" proxy "$@"

for network in $(docker container exec "$CONTAINER" ls /config); do
	if docker network inspect "$network" 1>/dev/null 2>&1; then
		docker network connect "$network" "$CONTAINER"
	fi
done
