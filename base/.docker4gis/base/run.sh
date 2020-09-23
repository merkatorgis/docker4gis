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
    [ "$old_image" = "$image" ] &&
        docker container start "$container" &&
        # Existing container from same image is started, and we're done.
        exit 0
    docker container rm -f "$container" >/dev/null || exit $?
fi

dir=$(mktemp -d)
finish() {
    rm -rf "$dir"
    exit "${1:-$?}"
}

if
    docker4gis="$(dirname "$0")"/.docker4gis.sh
    docker4gis_dir=$("$docker4gis" "$dir" "$image")
then
    pushd "$docker4gis_dir" >/dev/null || finish 1
    base/network.sh &&
        . base/docker_bind_source &&
        # Execute the (base) image's run script,
        # passing args read from its args file,
        # substituting environment variables,
        # and skipping lines starting with a #.
        envsubst <args | grep -v "^#" | xargs \
            ./run.sh "$repo" "$tag" "$@"
    popd >/dev/null || finish 1
fi

finish
