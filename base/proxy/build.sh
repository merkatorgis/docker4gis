#!/bin/bash

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"

repo=$(basename "$(pwd)")
container="${DOCKER_USER}-${repo}"
image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}"

echo; echo "Building ${image}"
docker container rm -f "${container}" 2>/dev/null

HERE=$(dirname "$0")

if [ -d ./goproxy ]; then # building base
	if (which go 1>/dev/null 2>&1); then

		cd ./goproxy
		export MSYS_NO_PATHCONV=1
		docker container run --rm \
			-v "$PWD":/usr/src/goproxy \
			-w /usr/src/goproxy \
			-e CGO_ENABLED=0 \
			-e GOOS=linux \
			golang \
			go build -v -a -tags netgo -ldflags '-w' .
		cd ..

		docker image build -t "${image}" .
	else
		echo 'Skipping build in absence of Go'
	fi
else # building upon base
	mkdir -p conf
	cp -r "${HERE}/../plugins" "conf"
	docker image build -t "${image}" .
	rm -rf "conf/plugins"
fi
