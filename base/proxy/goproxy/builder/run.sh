#!/bin/bash
set -e

here=$(dirname "$0")
docker image build -t goproxy "${here}"

export MSYS_NO_PATHCONV=1
docker container run --rm \
	-v "$(docker_bind_source "${PWD}/goproxy")":/usr/src/goproxy \
	goproxy
