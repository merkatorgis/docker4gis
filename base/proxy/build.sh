#!/bin/bash

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"

# repo=$(basename "$(pwd)")
container=docker4gis-proxy
image="${DOCKER_REGISTRY}${DOCKER_USER}/proxy"

. "${DOCKER_BASE}/docker_bind_source"

echo; echo "Building ${image}"

HERE=$(dirname "$0")

if [ -d goproxy ]; then # building base
	export MSYS_NO_PATHCONV=1
	if docker container run --rm \
		-v "$(docker_bind_source "${PWD}/goproxy")":/usr/src/goproxy \
		-w /usr/src/goproxy \
		-e CGO_ENABLED=0 \
		-e GOOS=linux \
		golang:1.13.5 \
		go build -v -a -tags netgo -ldflags '-w' .
	then
		docker image build -t "${image}" .
	fi
else # building upon base
	docker container rm -f "${container}" 2>/dev/null
	mkdir -p conf
	cp -r "${HERE}/../plugins" "conf"
	docker image build \
		--build-arg DOCKER_USER="${DOCKER_USER}" \
		-t "${image}" .
	rm -rf "conf/plugins"
fi
