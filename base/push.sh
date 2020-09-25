#!/bin/bash

DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER

mainscript=$1
repo=$2
tag=$3

dir=$(dirname "$mainscript")/"$repo"
dir=$(realpath "$dir")
[ "$repo" ] || exit 1
[ -d "$dir" ] || exit 1

[ "$repo" = .package ] && repo=package
image=$DOCKER_REGISTRY$DOCKER_USER/$repo

docker image push "$image":latest
[ "$tag" ] || exit

docker image tag "$image":latest "$image":"$tag"
docker image push "$image":"$tag"

echo "$tag" >"$dir"/tag
echo ">>> Tag '$tag' written to '$dir/tag'" >&2
[ "$repo" = package ] ||
    echo ">>> Consider updating the package." >&2
