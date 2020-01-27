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

XMS="${XMS:-256m}"
XMX="${XMX:-2g}"

docker container run --name "${container}" \
	-e DOCKER_USER="${DOCKER_USER}" \
	-e JAVA_OPTS="-Xms${XMS} -Xmx${XMX} -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:+UseParNewGC -XX:NewRatio=2 -XX:+AggressiveOpts" \
	--network "${DOCKER_USER}" \
	"$@" \
	-d "${image}"
