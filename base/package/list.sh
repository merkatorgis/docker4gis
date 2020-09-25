#!/bin/bash

directive=$1

BASE=$BASE
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER

# compile a list of commands to run all repos' containers
get_repo() {
    basename "$repo_path"
}
first_repo() {
    pick_repo postgis mysql
}
last_repo() {
    pick_repo proxy
}
pick_repo() {
    local item
    local repo
    repo=$(get_repo)
    for item in "$@"; do
        [ "$item" = "$repo" ] && return 0
    done
    return 1
}
add_repo() {
    local repo
    repo=$(get_repo)
    local image=$DOCKER_REGISTRY$DOCKER_USER/$repo
    local tag
    [ -f "$repo_path"/tag ] &&
        tag=$(cat "$repo_path"/tag)
    [ "$directive" = dirty ] &&
        docker image tag "$image:dirty" "$image:dirty" >/dev/null 2>&1 &&
        tag=dirty
    [ "$directive" = latest ] &&
        docker image pull "$image:latest" >/dev/null 2>&1 &&
        tag=latest
    echo "$BASE/docker4gis/run.sh $repo $tag"
}
for repo_path in */; do
    first_repo && add_repo
done
for repo_path in */; do
    first_repo || last_repo || add_repo
done
for repo_path in */; do
    last_repo && add_repo
done
