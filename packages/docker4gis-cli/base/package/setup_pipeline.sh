#!/bin/bash

# shellcheck disable=SC2016

DOCKER_ENV=${1:-${DOCKER_ENV:-DEVELOPMENT}}
[ "$DOCKER_ENV" ] || echo "# change to DEVELOPMENT, TEST, or PRODUCTION"
echo "export DOCKER_ENV=${DOCKER_ENV:-'$DOCKER_ENV'}"

echo -n '
# change to your fully qualified domain name, e.g. www.example.com
export PROXY_HOST=$PROXY_HOST

# set to true to get a certificate through LetsEncrypt
export AUTOCERT=false

# rest is fully optional

# default is ~/docker-binds
export DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

export DEBUG=$DEBUG

export APP=$APP
export API=$API
export HOMEDEST=$HOMEDEST

export XMS=$XMS
export XMX=$XMX

export POSTGRES_LOG_STATEMENT=
# export POSTGRES_LOG_STATEMENT=ddl
# export POSTGRES_LOG_STATEMENT=all

export POSTFIX_DESTINATION=${POSTFIX_DESTINATION:-$PROXY_HOST}
export POSTFIX_DOMAIN=${POSTFIX_DOMAIN:-$POSTFIX_DESTINATION}

export OSM_THREADS=$OSM_THREADS
export OSM_CACHE_MB=$OSM_CACHE_MB

eval "$(docker container run --rm '
echo -n "$DOCKER_REGISTRY/$DOCKER_USER/package"
echo ':"$tag" /run.sh)"'
