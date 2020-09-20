#!/bin/bash
set -e

DOCKER_BASE="$DOCKER_BASE"
DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="${DOCKER_USER:-docker4gis}"

repo=proxy
container="docker4gis-$repo"
image="$DOCKER_REGISTRY$DOCKER_USER/$repo"

echo
echo "Building $image"

mkdir -p conf
cp -r "$DOCKER_BASE"/plugins "$DOCKER_BASE"/utils "conf"
if [ -d goproxy ]; then # building base
	if goproxy/builder/run.sh; then
		docker image build -t "${image}" .
	fi
else # building upon base
	docker container rm -f "$container" 2>/dev/null
	docker image build \
		--build-arg DOCKER_USER="$DOCKER_USER" \
		-t "$image" .
fi
rm -rf "conf/plugins" "conf/utils"
