#!/usr/bin/bash
set -e

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkator}"
DOCKER_REPO="${DOCKER_REPO:-proxy}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
PROXY_CONTAINER="${PROXY_CONTAINER:-$DOCKER_USER-px}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

HERE=$(dirname "$0")
"$HERE/../rename.sh" "$IMAGE" "$PROXY_CONTAINER" force

if [ -d ./goproxy ]; then # building base
	if (which go 1>/dev/null 2>&1); then

		cd ./goproxy
		CGO_ENABLED=0 GOOS=linux go build -a -tags netgo -ldflags '-w' .
		cd ..

		docker build -t $IMAGE .
	else
		echo 'Skipping build in absence of Go'
	fi
else # building upon base
	docker build -t $IMAGE .
fi
