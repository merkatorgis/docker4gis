#!/bin/bash
set -e

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
    docker container rm -f "$container" >/dev/null
fi

dir=$(mktemp -d)
"$(dirname "$0")"/base.sh "$dir" "$image"

# Execute the actual run script,
# and ensure that we survive, to remain able to clean up.
if pushd "$dir"/.docker4gis >/dev/null &&
    base/network.sh &&
    . base/docker_bind_source &&
    # pass args from args file,
    # substituting environment variables,
    # and skipping lines starting with a #
    envsubst <args | grep -v "^#" | xargs \
        ./run.sh "$repo" "$tag" &&
    popd >/dev/null; then
    true
fi

if [ -d "$dir" ]; then
    rm -rf "$dir"
fi
