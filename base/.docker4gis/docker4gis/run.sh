#!/bin/bash

repo="$1"
tag="${2:-$(cat "$repo"/tag)}"
shift 2

DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="$DOCKER_USER"

image="$DOCKER_REGISTRY""$DOCKER_USER"/"$repo":"$tag"
[ "$repo" = proxy ] &&
    container="docker4gis-proxy" ||
    container="$DOCKER_USER"-"$repo"
echo
echo "Starting $container from $image..."

if old_image=$(docker container inspect --format='{{ .Config.Image }}' "$container" 2>/dev/null); then
    [ "$old_image" = "$image" ] && docker container start "$container" &&
        exit 0 || # Existing container from same image is started, and we're done.
        echo "The existing container failed to start; we'll remove it, and create a new one..."
    docker container rm -f "$container" >/dev/null || exit $?
fi

temp=$(mktemp -d)
finish() {
    rm -rf "$temp"
    exit "${1:-$?}"
}

if
    dotdocker4gis="$(dirname "$0")"/.docker4gis.sh
    BASE=$("$dotdocker4gis" "$temp" "$image")
then
    pushd "$BASE" >/dev/null || finish 1
    docker4gis/network.sh &&
        # Execute the (base) image's run script,
        # passing args read from its args file,
        # substituting environment variables,
        # and skipping lines starting with a #.
        envsubst <args | grep -v "^#" | xargs \
            ./run.sh "$repo" "$tag" "$@"
    popd >/dev/null || finish 1
fi

finish
