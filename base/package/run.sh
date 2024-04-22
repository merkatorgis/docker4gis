#!/bin/bash

echo "export DOCKER_USER=$DOCKER_USER"
echo "export DOCKER_REGISTRY=$DOCKER_REGISTRY"
# shellcheck disable=SC2016
echo '
[ "$tag" ] || echo "Please pass a specific tag."
[ "$tag" ] || exit 1

export DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR
if [ ! "$DOCKER_BINDS_DIR" ]; then
	DOCKER_BINDS_DIR=$(realpath ~)/docker-binds
	export DOCKER_BINDS_DIR
fi

log=$(realpath "$DOCKER_USER".log)

echo "
$(date)

Running package $DOCKER_USER version: $tag

With these settings:

DOCKER_ENV=$DOCKER_ENV

PROXY_HOST=$PROXY_HOST
AUTOCERT=$AUTOCERT

DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR
DOCKER_REGISTRY=$DOCKER_REGISTRY

DEBUG=$DEBUG

SECRET=$SECRET
API=$API
AUTH_PATH=$AUTH_PATH
APP=$APP
HOMEDEST=$HOMEDEST

XMS=$XMS
XMX=$XMX

GEOSERVER_XMS=$GEOSERVER_XMS
GEOSERVER_XMX=$GEOSERVER_XMX

POSTGRES_LOG_STATEMENT=$POSTGRES_LOG_STATEMENT

POSTFIX_DESTINATION=$POSTFIX_DESTINATION
POSTFIX_DOMAIN=$POSTFIX_DOMAIN

OSM_THREADS=$OSM_THREADS
OSM_CACHE_MB=$OSM_CACHE_MB
" | tee -a "$log"

read -rn 1 -p "Press any key to continue..."

echo "
Executing $DOCKER_REGISTRY$DOCKER_USER/package:$tag
" | tee -a "$log"

temp=$(mktemp -d)
container=$(docker container create "$DOCKER_REGISTRY/$DOCKER_USER/package:$tag")
docker container cp "$container":/.docker4gis "$temp"
docker container rm "$container" >/dev/null
"$temp"/.docker4gis/run.sh | tee -a "$log"
rm -rf "$temp"

echo "$(docker container ls)" | tee -a "$log"
'
