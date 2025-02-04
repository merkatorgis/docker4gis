#!/bin/bash

IMAGE=${IMAGE:-docker4gis/package}
DOCKER_BASE=$DOCKER_BASE
DOCKER4GIS_VERSION=$DOCKER4GIS_VERSION
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER

[ "$IMAGE" = docker4gis/package ] || extension=true

mkdir -p conf

finish() {
    local exit_code=${1:-0}
    [ "$exit_code" = 127 ] && exit_code=0

    rm -rf conf
    [ "$extension" ] && [ -f Dockerfile ] && rm Dockerfile

    exit "$exit_code"
}

[ "$extension" ] && {
    # We're building a concrete application's package image (i.e. an extension
    # of the base docker4gis/package image, as opposed to that base image
    # itself); compile a list of commands to run its containers.
    runscript=conf/run.sh
    echo '#!/bin/bash' >"$runscript"
    # echo 'set -x' >>"$runscript"
    # echo 'find .' >>"$runscript"
    chmod +x "$runscript"
    here=$(realpath "$(dirname "$0")")
    BASE='' "$here"/list.sh >>"$runscript" || finish "$?"
    if [ "$DOCKER4GIS_VERSION" = development ]; then
        # This would just be a debugging/testing situation.
        tag=latest
    else
        tag=v$DOCKER4GIS_VERSION
    fi
    echo "FROM docker4gis/package:$tag" >Dockerfile
}

[ "$extension" ] || DOCKER_BASE=$(dirname "$0")/..

cp -r "$DOCKER_BASE"/.docker4gis conf
docker image build \
    --build-arg DOCKER_USER="$DOCKER_USER" \
    --build-arg DOCKER_REGISTRY="$DOCKER_REGISTRY" \
    -t "$IMAGE" .

finish
