#!/bin/bash

[ "$IMAGE" ] || base=true
IMAGE=${IMAGE:-docker4gis/$(basename "$(realpath .)")}
DOCKER_BASE=$DOCKER_BASE

mkdir -p conf
cp -r "$DOCKER_BASE"/plugins "$DOCKER_BASE"/.docker4gis conf
if [ "$base" ]; then
	goproxy/builder/run.sh &&
		docker image build -t "$IMAGE" .
else
	docker image build \
		--build-arg DOCKER_USER="$DOCKER_USER" \
		-t "$IMAGE" .
fi
rm -rf conf/plugins conf/.docker4gis
