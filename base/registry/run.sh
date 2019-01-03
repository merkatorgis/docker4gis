#!/bin/bash
set -e
export MSYS_NO_PATHCONV=1

REGISTRY_HOST="${REGISTRY_HOST:-localhost}"
REGISTRY_PORT="${REGISTRY_PORT:-443}"
DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkator}"
DOCKER_REPO="${DOCKER_REPO:-registry}"
DOCKER_TAG="${DOCKER_TAG:-latest}"

CONTAINER="$DOCKER_REPO"
IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Running $CONTAINER from $IMAGE"

docker volume create certificates
docker volume create registry
if (docker network create registry 2>/dev/null); then true; fi

docker container run --name $CONTAINER \
	--network registry \
	-v certificates:/certificates \
	-e REGISTRY_HOST=$REGISTRY_HOST \
	-p $REGISTRY_PORT:443 \
	"$@" \
	-d "$IMAGE"

docker container run --name theregistry \
	--network registry \
	-v certificates:/certificates \
	-v registry:/var/lib/registry \
	-e "REGISTRY_AUTH=htpasswd" \
	-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
	-e REGISTRY_AUTH_HTPASSWD_PATH=/var/lib/registry/htpasswd \
	-e REGISTRY_HTTP_ADDR=0.0.0.0:443 \
	-e REGISTRY_HTTP_TLS_CERTIFICATE=/certificates/$REGISTRY_HOST.crt \
	-e REGISTRY_HTTP_TLS_KEY=/certificates/$REGISTRY_HOST.key \
	-d registry:2
