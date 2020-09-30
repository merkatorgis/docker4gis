#!/bin/bash

# shellcheck disable=SC2016
echo '
export DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR
if [ ! "$DOCKER_BINDS_DIR" ]; then
	DOCKER_BINDS_DIR=$(realpath ~)/docker-binds
	export DOCKER_BINDS_DIR
fi

log=$(realpath "$DOCKER_USER".log)

echo "
$(date)

Running package $DOCKER_USER version: $TAG

With these settings:

DOCKER_ENV=$DOCKER_ENV

PROXY_HOST=$PROXY_HOST
AUTOCERT=$AUTOCERT

DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR
DOCKER_REGISTRY=$DOCKER_REGISTRY

SECRET=$SECRET
APP=$APP
API=$API
HOMEDEST=$HOMEDEST

XMS=$XMS
XMX=$XMX

POSTFIX_DESTINATION=$POSTFIX_DESTINATION
POSTFIX_DOMAIN=$POSTFIX_DOMAIN
" | tee -a "$log"

read -rn 1 -p "Press any key to continue..."

echo "
Executing $DOCKER_REGISTRY$DOCKER_USER/package:$tag" | tee -a "$log"

temp=$(mktemp -d)
container=$(docker container create "$DOCKER_REGISTRY$DOCKER_USER/package:$tag")
docker container cp "$container":/.docker4gis "$temp"
docker container rm "$container" >/dev/null
"$temp"/.docker4gis/run.sh | tee -a "$log"
rm -rf "$temp"

echo "
$(docker container ls)" | tee -a "$log"
'
