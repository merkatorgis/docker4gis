#!/bin/bash
set -e
export MSYS_NO_PATHCONV=1

tag=${1:-latest}
REGISTRY_HOST=${REGISTRY_HOST:-localhost}
REGISTRY_PORT=${REGISTRY_PORT:-443}
AUTOCERT=${AUTOCERT:-false}
DOCKER_ENV=${DOCKER_ENV:-DEVELOPMENT}

docker volume create certificates
docker volume create registry
if (docker network create registry 2>/dev/null); then true; fi

docker container run --restart always --name registry \
	--network registry \
	-v certificates:/certificates \
	-e REGISTRY_HOST="$REGISTRY_HOST" \
	-e AUTOCERT="$AUTOCERT" \
	-e DOCKER_ENV="$DOCKER_ENV" \
	-p "$REGISTRY_PORT":443 \
	-d docker4gis/registry:"$tag"

docker container run --restart always --name theregistry \
	--network registry \
	-v certificates:/certificates \
	-v registry:/var/lib/registry \
	-e "REGISTRY_AUTH=htpasswd" \
	-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
	-e REGISTRY_AUTH_HTPASSWD_PATH=/var/lib/registry/htpasswd \
	-e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
	-e REGISTRY_HTTP_TLS_CERTIFICATE=/certificates/localhost.crt \
	-e REGISTRY_HTTP_TLS_KEY=/certificates/localhost.key \
	-e REGISTRY_STORAGE_DELETE_ENABLED=true \
	-d registry:2
