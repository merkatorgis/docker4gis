#!/bin/bash

repo=$1
tag=${2:-$(cat "$repo"/tag)}
shift 2

DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR
DOCKER_ENV=${DOCKER_ENV:-DEVELOPMENT}
export DOCKER_ENV

IMAGE=$DOCKER_REGISTRY$DOCKER_USER/$repo:$tag
[ "$repo" = proxy ] &&
    CONTAINER=docker4gis-proxy ||
    CONTAINER=$DOCKER_USER-$repo
export IMAGE
export CONTAINER
echo
echo "Starting $CONTAINER from $IMAGE..."

if old_image=$(docker container inspect --format='{{ .Config.Image }}' "$CONTAINER" 2>/dev/null); then
    [ "$old_image" = "$IMAGE" ] && docker container start "$CONTAINER" &&
        exit 0 || # Existing container from same image is started, and we're done.
        echo "The existing container failed to start; we'll remove it, and create a new one..."
    docker container rm -f "$CONTAINER" >/dev/null || exit $?
fi

temp=$(mktemp -d)
finish() {
    rm -rf "$temp"
    exit "${1:-$?}"
}

if
    dotdocker4gis="$(dirname "$0")"/.docker4gis.sh
    BASE=$("$dotdocker4gis" "$temp" "$IMAGE")
then
    pushd "$BASE" >/dev/null || finish 1
    docker4gis/network.sh &&
        # Execute the (base) image's run script,
        # passing args read from its args file,
        # substituting environment variables,
        # and skipping lines starting with a #.
        envsubst <args | grep -v "^#" | xargs \
            ./run.sh "$@"
    popd >/dev/null || finish 1
fi

finish
