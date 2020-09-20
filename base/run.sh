#!/bin/bash
set -e

repo="$1"
tag="${2:-$(cat "$repo"/tag)}"

DOCKER_BASE="$DOCKER_BASE"
DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="$DOCKER_USER"

image="$DOCKER_REGISTRY$DOCKER_USER/$repo:$tag"

dir=$(mktemp -d)
"$DOCKER_BASE"/base.sh "$dir" "$image"

# Execute the actual run script,
# and ensure that we survive, to remain able to clean up.
if
    pushd "$dir" && \
    . docker_bind_source && \
    ./args.sh | xargs ./run.sh "$repo" "$tag" && \
    popd
then
    true
fi

if [ -d "$dir" ]; then
    rm -rf "$dir"
fi
