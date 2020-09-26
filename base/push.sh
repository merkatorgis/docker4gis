#!/bin/bash
set -e

DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_APP_DIR=$DOCKER_APP_DIR

repo=$1
tag=$2

dir=$DOCKER_APP_DIR/$repo
[ "$repo" ] || exit 1
[ -d "$dir" ] || exit 1

[ "$repo" = .package ] && repo=package
image=$DOCKER_REGISTRY$DOCKER_USER/$repo

docker image tag "$image":dirty "$image":latest
docker image push "$image":latest
docker image rm -f "$image":latest
[ "$tag" ] || exit

docker image tag "$image":dirty "$image":"$tag"
docker image push "$image":"$tag"
docker image rm -f "$image":dirty

echo "$tag" >"$dir"/tag
