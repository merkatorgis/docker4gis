#!/bin/bash

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-proxy}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
PROXY_CONTAINER="${PROXY_CONTAINER:-$DOCKER_USER-px}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"
docker container rm -f "${PROXY_CONTAINER}" 2>/dev/null

HERE=$(dirname "$0")

if [ -d ./goproxy ]; then # building base
	if (which go 1>/dev/null 2>&1); then

		cd ./goproxy
		CGO_ENABLED=0 GOOS=linux go build -a -tags netgo -ldflags '-w' .
		cd ..

		docker image build -t "${IMAGE}" .
	else
		echo 'Skipping build in absence of Go'
	fi
else # building upon base
	mkdir -p conf
	cp -r "${HERE}/../plugins" "conf"
	docker image build -t "${IMAGE}" .
	rm -rf "conf/plugins"
fi
