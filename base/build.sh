#!/bin/bash
basedir=$(dirname "${1}")
what="${2}"
export DOCKER_TAG="${3:-latest}"
shift 3

curdir=$(pwd);
cd "${basedir}"; basedir=$(pwd) # make the path absolute

cd "${basedir}/${what}"
./build.sh "$@"

cd "${curdir}"
