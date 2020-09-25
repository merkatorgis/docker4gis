#!/bin/bash
set -e

repo=$1
tag=$2
shift 2

DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

container=$DOCKER_USER-$repo
image=$DOCKER_REGISTRY$DOCKER_USER/$repo:$tag

XMS=${XMS:-256m}
XMX=${XMX:-2g}

docker container run --restart always --name "$container" \
	-e DOCKER_USER="$DOCKER_USER" \
	-e JAVA_OPTS="-Xms$XMS -Xmx$XMX -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:+UseParNewGC -XX:NewRatio=2 -XX:+AggressiveOpts" \
	--network "$DOCKER_USER" \
	"$@" \
	-d "$image"
