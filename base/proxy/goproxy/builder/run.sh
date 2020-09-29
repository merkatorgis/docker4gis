#!/bin/bash
set -e

here=$(dirname "$0")
docker image build -t goproxy "$here"

export MSYS_NO_PATHCONV=1
docker container run --rm \
	-v "$("$DOCKER_BASE"/.docker4gis/docker4gis/bind.sh "$PWD"/goproxy /usr/src/goproxy)" \
	goproxy
