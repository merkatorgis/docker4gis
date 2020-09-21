#!/bin/bash
set -e

docker_tag="${1:-latest}"

export DOCKER_REGISTRY="$DOCKER_REGISTRY"
export DOCKER_USER="$DOCKER_USER"
export DOCKER_ENV="$DOCKER_ENV"
export PROXY_HOST="$PROXY_HOST"
export AUTOCERT="$AUTOCERT"

export SECRET="$SECRET"
export APP="$APP"
export API="$API"
export HOMEDEST="$HOMEDEST"

export XMS="$XMS"
export XMX="$XMX"

export POSTFIX_DESTINATION="$POSTFIX_DESTINATION"
export POSTFIX_DOMAIN="$POSTFIX_DOMAIN"

export DOCKER_BINDS_DIR="$DOCKER_BINDS_DIR"
if [ ! "$DOCKER_BINDS_DIR" ]; then
	DOCKER_BINDS_DIR=$(realpath ~)/docker-binds
	export DOCKER_BINDS_DIR
fi

echo "
$(date)

Running package '$DOCKER_USER' version: $docker_tag

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
" | tee -a "$DOCKER_USER".log

read -rn 1 -p 'Press any key to continue...'

image="$DOCKER_REGISTRY""$DOCKER_USER"/package:"$docker_tag"

echo "
Executing $image" | tee -a "$DOCKER_USER".log

container=$(docker container create "$image")
docker container cp "$container":/.docker4gis .
docker container rm "$container" >/dev/null

.docker4gis/run.sh | tee -a "$DOCKER_USER".log

echo "
$(docker container ls)" | tee -a "$DOCKER_USER".log

rm -rf .docker4gis
