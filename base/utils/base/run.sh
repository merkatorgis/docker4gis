#!/bin/bash

repo="$1"
tag="${2:-$(cat "$repo"/tag)}"

DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="$DOCKER_USER"

image="$DOCKER_REGISTRY""$DOCKER_USER"/"$repo":"$tag"

if [ "$repo" = proxy ]; then
    container=docker4gis-proxy
else
    container="$DOCKER_USER"-"$repo"
fi

echo
echo "Starting $container from $image..."

if container_ls=$(docker container ls -a | grep "$container$"); then
    old_image=$(echo "$container_ls" | awk '{print $2}')
    if [ "$old_image" = "$image" ]; then
        if docker container start "$container"; then
            exit
        else
            echo "Starting existing container failed; creating a new one..."
        fi
    fi
    if ! docker container rm -f "$container" >/dev/null; then
        exit 1
    fi
fi

dir=$(mktemp -d)
finish() {
    rm -rf "$dir"
    exit "${1:-$?}"
}
# copy the base image's scripts to the temp dir
"$(dirname "$0")"/base.sh "$dir" "$image"
# execute the base image's run script
pushd "$dir"/.docker4gis >/dev/null || finish 1
base/network.sh &&
    . base/docker_bind_source &&
    # pass args from args file,
    # substituting environment variables,
    # and skipping lines starting with a #
    envsubst <args | grep -v "^#" | xargs \
        ./run.sh "$repo" "$tag"
popd >/dev/null || finish 1

finish
