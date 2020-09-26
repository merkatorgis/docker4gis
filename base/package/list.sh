#!/bin/bash

directive=$1

BASE=$BASE
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_APP_DIR=${DOCKER_APP_DIR:-.}

# compile a list of commands to run all repos' containers

pick_repo() {
    local item
    for item in "$@"; do
        [ "$item" = "$repo" ] && return 0
    done
    return 1
}
add_repo() {
    local image=$DOCKER_REGISTRY$DOCKER_USER/$repo
    local tag
    [ -f "$repo_path"/tag ] && tag=$(cat "$repo_path"/tag)
    if [ "$directive" = latest ]; then
        docker image pull "$image:latest" >/dev/null 2>&1 &&
            tag=latest ||
            tag=tsetal
    fi
    if [ "$directive" = dirty ] || [ "$tag" = tsetal ]; then
        # use dirty image _if_ it exists
        docker image tag "$image:dirty" "$image:dirty" >/dev/null 2>&1 &&
            tag=dirty
    fi
    [ "$tag" = tsetal ] &&
        echo "echo ERROR: no image found for '$image'" ||
        echo "$BASE/docker4gis/run.sh $repo $tag"
}
first_repo() {
    pick_repo postgis mysql
}
last_repo() {
    pick_repo proxy
}
for repo_path in "$DOCKER_APP_DIR"/*/; do
    repo=$(basename "$repo_path")
    first_repo && add_repo
done
for repo_path in "$DOCKER_APP_DIR"/*/; do
    repo=$(basename "$repo_path")
    first_repo || last_repo || add_repo
done
for repo_path in "$DOCKER_APP_DIR"/*/; do
    repo=$(basename "$repo_path")
    last_repo && add_repo
done
