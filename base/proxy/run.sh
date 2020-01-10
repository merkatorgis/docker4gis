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

HOMEDEST="${HOMEDEST}"
SECRET="${SECRET}"

API="${API:-http://${DOCKER_USER}-api:8080}"
APP="${APP:-http://${DOCKER_USER}-app}"

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

docker volume create docker4gis-proxy
docker run --name "${container}" \
	-e PROXY_HOST=$PROXY_HOST \
	-e HOMEDEST=$HOMEDEST \
	-e DOCKER_USER=$DOCKER_USER \
	-e SECRET=$SECRET \
	-e API=${API} \
	-e APP=${APP} \
	--mount source=docker4gis-proxy,target=/config \
	-p $PROXY_PORT:443 \
	--network "${DOCKER_USER}-net" \
	--add-host=$(hostname):$(getip $(hostname)) \
	--add-host="${PROXY_HOST}":$(getip $(urlhost "${API}")) \
	-d $image proxy	"$@"
