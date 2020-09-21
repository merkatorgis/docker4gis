#!/bin/bash
set -e

repo="$1"
tag="${2:-$(cat "$repo"/tag)}"

DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="$DOCKER_USER"

image="$DOCKER_REGISTRY""$DOCKER_USER"/"$repo":"$tag"

dir=$(mktemp -d)
pushd "$(dirname "$0")" >/dev/null
./base.sh "$dir" "$image"
popd >/dev/null

# Execute the actual run script,
# and ensure that we survive, to remain able to clean up.
if pushd "$dir"/.docker4gis >/dev/null &&
    . base/docker_bind_source &&
    envsubst <args | grep -v "^#" | xargs \
        ./run.sh "$repo" "$tag" &&
    popd >/dev/null; then
    true
fi

if [ -d "$dir" ]; then
    rm -rf "$dir"
fi
