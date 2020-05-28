#!/bin/bash

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"

# repo=$(basename "$(pwd)")
container=docker4gis-proxy
image="${DOCKER_REGISTRY}${DOCKER_USER}/proxy"

. "${DOCKER_BASE}/docker_bind_source"

echo; echo "Building ${image}"

here=$(dirname "$0")

if [ -d goproxy ]; then # building base
	if goproxy/builder/run.sh
	then
		docker image build -t "${image}" .
	fi
else # building upon base
	docker container rm -f "${container}" 2>/dev/null
	mkdir -p conf
	cp -r "${here}/../plugins" "conf"
	docker image build \
		--build-arg DOCKER_USER="${DOCKER_USER}" \
		-t "${image}" .
	rm -rf "conf/plugins"
fi
