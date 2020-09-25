#!/bin/bash
set -e

[ "$IMAGE" ] || base=true
IMAGE=${IMAGE:-docker4gis/$(basename "$(realpath .)")}
DOCKER_BASE=$DOCKER_BASE

if [ "$base" ]; then
	which go
	cd ./goproxy
	CGO_ENABLED=0 GOOS=linux go build -a -tags netgo -ldflags '-w' .
	cd ..
	docker build -t "$IMAGE" .
else
	docker build -t "$IMAGE" .
fi
