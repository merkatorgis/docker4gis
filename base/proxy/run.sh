#!/bin/bash
set -e

repo="$1"
tag="$2"
shift 2

PROXY_HOST="${PROXY_HOST:-localhost}"
PROXY_PORT="${PROXY_PORT:-443}"
PROXY_PORT_HTTP="${PROXY_PORT_HTTP:-80}"
AUTOCERT="${AUTOCERT:-false}"

DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="$DOCKER_USER"
DOCKER_ENV="${DOCKER_ENV:-DEVELOPMENT}"
DOCKER_BINDS_DIR="$DOCKER_BINDS_DIR"

container=docker4gis-proxy
image="$DOCKER_REGISTRY""$DOCKER_USER"/"$repo":"$tag"

SECRET="$SECRET"
API="$API"
APP="$APP"
HOMEDEST="$HOMEDEST"

noop() {
	name="$1"
	value="$2"
	if [ "$value" ]; then
		echo "$name"="$value"
	else
		echo noop=noop
	fi
}

if base/start.sh "$image" "$container"; then exit; fi

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

network="$container"
base/network.sh "$network"

volume="$container"
docker volume create "$volume"

PROXY_PORT=$(base/port.sh "$PROXY_PORT")
PROXY_PORT_HTTP=$(base/port.sh "$PROXY_PORT_HTTP")

docker container run --restart always --name "$container" \
	-e PROXY_HOST="$PROXY_HOST" \
	-e PROXY_PORT="$PROXY_PORT" \
	-e AUTOCERT="$AUTOCERT" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-e "$(noop SECRET "$SECRET")" \
	-e "$(noop API "$API")" \
	-e "$(noop APP "$APP")" \
	-e "$(noop HOMEDEST "$HOMEDEST")" \
	-v "$(docker_bind_source "$DOCKER_BINDS_DIR"/certificates)":/certificates \
	--mount source="$volume",target=/config \
	-p "$PROXY_PORT":443 \
	-p "$PROXY_PORT_HTTP":80 \
	--network "$network" \
	--add-host="$(hostname)":"$(getip "$(hostname)")" \
	-d "$image" proxy "$@"

for network in $(docker container exec "$container" ls /config); do
	if docker network inspect "$network" 1>/dev/null 2>&1; then
		docker network connect "$network" "$container"
	fi
done
