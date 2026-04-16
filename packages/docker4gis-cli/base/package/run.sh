#!/bin/bash

echo "export DOCKER_USER=$DOCKER_USER"
echo "export DOCKER_REGISTRY=$DOCKER_REGISTRY"
# shellcheck disable=SC2016
echo '
tag=${tag:?Please pass a specific tag}

base_dir=~
[ -n "$PIPELINE" ] && base_dir=..
DOCKER_BINDS_DIR=${DOCKER_BINDS_DIR:-$base_dir/docker-binds}
DOCKER_BINDS_DIR=$(realpath "$DOCKER_BINDS_DIR")
export DOCKER_BINDS_DIR

log=$(realpath "$DOCKER_USER".log)

# Tee all stdout & stderr to a log file (from
# https://superuser.com/a/212436/462952).
exec > >(tee -a "$log") 2>&1

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

API=$API
AUTH_PATH=$AUTH_PATH
APP=$APP
HOMEDEST=$HOMEDEST

XMS=$XMS
XMX=$XMX

POSTGRES_LOG_STATEMENT=$POSTGRES_LOG_STATEMENT

POSTFIX_DESTINATION=$POSTFIX_DESTINATION
POSTFIX_DOMAIN=$POSTFIX_DOMAIN

OSM_THREADS=$OSM_THREADS
OSM_CACHE_MB=$OSM_CACHE_MB
"

read -rn 1 -p "Press any key to continue..."

echo "
Executing $DOCKER_REGISTRY/$DOCKER_USER/package:$tag
"
'

cat /.docker4gis/run.sh

echo '
docker container ls'
