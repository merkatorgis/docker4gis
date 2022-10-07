#!/bin/bash

[ "$IMAGE" ] && extension=true
IMAGE=${IMAGE:-docker4gis/package}
DOCKER_BASE=$DOCKER_BASE
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER

mkdir -p conf

finish() {
    rm -rf conf
    exit "${1:-0}"
}

if [ "$extension" ]; then
    # We're building a concrete application's package image; compile a list of
    # commands to run its containers (otherwise, we're building the base
    # docker4gis/package image).
    runscript=conf/run.sh
    echo '#!/bin/bash' >"$runscript"
    # echo 'set -x' >>"$runscript"
    # echo 'find .' >>"$runscript"
    chmod +x "$runscript"
    here=$(realpath "$(dirname "$0")")
    # shellcheck disable=SC2016
    # Set BASE to the .docker4gis directory that was copied out of the base
    # docker4gis/package image, containing both build.sh ($0) and list.sh,
    # put there by the Dockerfile.
    BASE='"$(dirname "$0")"' "$here"/list.sh >>"$runscript" || finish 1
fi

cp -r "$DOCKER_BASE"/.docker4gis conf
docker image build \
    --build-arg DOCKER_USER="$DOCKER_USER" \
    --build-arg DOCKER_REGISTRY="$DOCKER_REGISTRY" \
    -t "$IMAGE" .

finish
