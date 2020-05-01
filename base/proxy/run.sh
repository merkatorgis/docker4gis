#!/bin/bash
set -e

PROXY_HOST="${PROXY_HOST:-localhost}"
PROXY_PORT="${PROXY_PORT:-443}"
PROXY_PORT_HTTP="${PROXY_PORT_HTTP:-80}"
AUTOCERT="${AUTOCERT:-false}"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER}"
DOCKER_TAG="${DOCKER_TAG}"
DOCKER_ENV="${DOCKER_ENV:-DEVELOPMENT}"
DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR}"

# repo=$(basename "$0")
container=docker4gis-proxy
image="${DOCKER_REGISTRY}${DOCKER_USER}/proxy:${DOCKER_TAG}"

SECRET="${SECRET}"
API="${API}"
APP="${APP}"
HOMEDEST="${HOMEDEST}"

secret()   { if [ "${SECRET}"   ]; then echo "-e SECRET=${SECRET}";     fi }
api()      { if [ "${API}"      ]; then echo "-e API=${API}";           fi }
app()      { if [ "${APP}"      ]; then echo "-e APP=${APP}";           fi }
homedest() { if [ "${HOMEDEST}" ]; then echo "-e HOMEDEST=${HOMEDEST}"; fi }

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

network="${container}"
.run/network.sh "${network}"

volume="${container}"
docker volume create "${volume}"

PROXY_PORT=$(.run/port.sh "${PROXY_PORT}")
PROXY_PORT_HTTP=$(.run/port.sh "${PROXY_PORT_HTTP}")

docker container run --name "${container}" \
	-e PROXY_HOST="${PROXY_HOST}" \
	-e PROXY_PORT="${PROXY_PORT}" \
	-e AUTOCERT="${AUTOCERT}" \
	-e DOCKER_ENV="${DOCKER_ENV}" \
	$(secret) $(api) $(app) $(homedest) \
	-v "$(docker_bind_source "${DOCKER_BINDS_DIR}/certificates")":/certificates \
	--mount source="${volume}",target=/config \
	-p "${PROXY_PORT}":443 \
	-p "${PROXY_PORT_HTTP}":80 \
	--network "${network}" \
	--add-host=$(hostname):$(getip $(hostname)) \
	-d "${image}" proxy	"$@"

for network in $(docker container exec "${container}" ls /config)
do
	if docker network inspect "${network}" 1>/dev/null 2>&1
	then
		docker network connect "${network}" "${container}"
	fi
done
