#!/bin/bash

basedir=$(dirname "$1")
repo="$2"
shift 2

curdir=$(pwd);
cd "${basedir}"; basedir=$(pwd) # make the path absolute

. "${DOCKER_BASE}/docker_bind_source"

cd "${basedir}/${repo}"
./build.sh "$@"

cd "${curdir}"
