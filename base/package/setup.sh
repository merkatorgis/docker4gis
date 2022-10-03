#!/bin/bash

# shellcheck disable=SC2016
echo -n '#!/bin/bash

tag=$1

export DOCKER_ENV=$DOCKER_ENV
export PROXY_HOST=$PROXY_HOST
export AUTOCERT=$AUTOCERT

export DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR

export DEBUG=$DEBUG

export SECRET=$SECRET
export APP=$APP
export API=$API
export HOMEDEST=$HOMEDEST

export XMS=$XMS
export XMX=$XMX

export POSTGRES_LOG_STATEMENT=
# export POSTGRES_LOG_STATEMENT=ddl
# export POSTGRES_LOG_STATEMENT=all

export POSTFIX_DESTINATION=$POSTFIX_DESTINATION
export POSTFIX_DOMAIN=$POSTFIX_DOMAIN

export OSM_THREADS=$OSM_THREADS
export OSM_CACHE_MB=$OSM_CACHE_MB

eval "$(docker container run --rm '
echo -n "$DOCKER_REGISTRY$DOCKER_USER/package"
# shellcheck disable=SC2016
echo ':"$tag" /run.sh)"'
