#!/bin/bash
set -e

IMAGE=$IMAGE
CONTAINER=$CONTAINER
RESTART=$RESTART

DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

XMS=${XMS:-256m}
XMX=${XMX:-2g}

docker container run --restart "$RESTART" --name "$CONTAINER" \
	-e DOCKER_USER="$DOCKER_USER" \
	-e JAVA_OPTS="-Xms$XMS -Xmx$XMX -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:+UseG1GC -XX:NewRatio=2 -XX:+AggressiveOpts" \
	--network "$DOCKER_USER" \
	"$@" \
	-d "$IMAGE"
