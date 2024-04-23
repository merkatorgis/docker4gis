#!/bin/bash

set -x

repo=$1
tag=$2
shift 2

DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
export DOCKER_ENV=${DOCKER_ENV:-DEVELOPMENT}
[ "$DOCKER_ENV" = DEVELOPMENT ] &&
    RESTART=no ||
    RESTART=always
export RESTART

FILEPORT=$DOCKER_BINDS_DIR/fileport/$DOCKER_USER/$repo
export FILEPORT
RUNNER=$DOCKER_BINDS_DIR/runner/$DOCKER_USER/$repo
export RUNNER

IMAGE=$DOCKER_REGISTRY/$DOCKER_USER/$repo:$tag
export IMAGE

CONTAINER=$DOCKER_USER-$repo
[ "$repo" = proxy ] && CONTAINER=docker4gis-proxy
export CONTAINER

NETWORK=$DOCKER_USER
[ "$repo" = proxy ] && NETWORK=$CONTAINER
export NETWORK

echo "Starting $CONTAINER from $IMAGE..."

# Pull the image from the registry if we don't have it locally, so that we
# have it ready to run a new container right after we stop the running one.
container=$(docker container create "$IMAGE") || exit 1
docker container rm "$container" >/dev/null

if old_image=$(docker container inspect --format='{{ .Config.Image }}' "$CONTAINER" 2>/dev/null); then
    if [ "$old_image" = "$IMAGE" ]; then
        docker container start "$CONTAINER" &&
            exit 0 || # Existing container from same image is started, and we're done.
            echo "The existing container failed to start; we'll remove it, and create a new one..."
    fi
    docker container stop "$CONTAINER" >/dev/null || exit $?
    docker container rm "$CONTAINER" >/dev/null || exit $?
fi

temp=$(mktemp -d)
finish() {
    err_code=${1:-$?}
    rm -rf "$temp"
    exit "$err_code"
}

docker4gis/network.sh "$NETWORK" || finish 2
export VOLUME=$CONTAINER
docker volume create "$VOLUME" >/dev/null || finish 5
# Execute the (base) image's run script,
# passing args read from its args file,
# substituting environment variables,
# and skipping lines starting with a #.
envsubst <args | grep -v "^#" | xargs \
    ./run.sh "$@"

finish "$?"
