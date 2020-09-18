#!/bin/bash

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"

container=docker4gis-proxy
image="${DOCKER_REGISTRY}${DOCKER_USER}/proxy"

echo
echo "Building ${image}"

cp -r "${DOCKER_BASE}/plugins" "conf"
if [ -d goproxy ]; then # building base
	if goproxy/builder/run.sh; then
		docker image build -t "${image}" .
	fi
else # building upon base
	docker container rm -f "${container}" 2>/dev/null
	docker image build \
		--build-arg DOCKER_USER="${DOCKER_USER}" \
		-t "${image}" .
fi
rm -rf "conf/plugins"
