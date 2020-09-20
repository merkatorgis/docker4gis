#!/bin/bash
set -e

here=$(dirname "$0")
docker image build -t goproxy "${here}"

export MSYS_NO_PATHCONV=1
. "${DOCKER_BASE}/utils/base/docker_bind_source"
docker container run --rm \
	-v "$(docker_bind_source "${PWD}/goproxy")":/usr/src/goproxy \
	goproxy
