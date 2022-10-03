#!/bin/bash

directive=$1

BASE=$BASE
DOCKER_BASE=$DOCKER_BASE
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_APP_DIR=${DOCKER_APP_DIR:-.}

# compile a list of commands to run all repos' containers

temp=$(mktemp)
repo=

finish() {
    rm -f "$temp"
    exit "${1:-0}"
}

error() {
    echo "> ERROR: $1" >&2
    finish 1
}

pick_repo() {
    local item
    for item in "$@"; do
        [ "$item" = "$repo" ] && return 0
    done
    return 1
}

local_image_exists() {
    docker image tag "$1" "$1" >/dev/null 2>&1
}

add_repo() {

    # Skip test as this is not a repo, but the folder containing the tests to
    # run after the containers are started.
    [ "$repo" = test ] && return

    # Skip base as this is not a repo, but the folder containing the files to
    # manage the docker4gis app.
    [ "$repo" = base ] && return

    echo "Fetching $repo..." >&2
    local image=$DOCKER_REGISTRY$DOCKER_USER/$repo
    local tag
    if [ "$directive" = dirty ] && local_image_exists "$image:latest"; then
        # use latest image _if_ it exists locally
        tag=latest
    else
        version_file=$repo_path/version
        if [ -f "$version_file" ]; then
            tag=$(cat "$version_file")
        else
            if [ "$directive" = dirty ]; then
                error "no image for '$repo'; was it built already?"
            else
                error "no version file for '$repo'; was it pushed already?"
            fi
        fi
        # use local image _if_ it exists
        local_image_exists "$image:$tag" ||
            # otherwise, try to find it in the registry
            docker image pull "$image:$tag" >/dev/null ||
            error "image '$image:$tag' not found"
    fi
    if [ "$tag" ]; then
        echo "$BASE/docker4gis/run.sh $repo $tag" >>"$temp"
        echo "$image:$tag" >&2
    else
        error "no tag for '$image'"
    fi
}

first_repo() {
    pick_repo postgis mysql
}

last_repo() {
    pick_repo proxy
}

for repo_path in "$DOCKER_APP_DIR"/*/; do
    repo=$("$DOCKER_BASE"/repo.sh "$repo_path")
    first_repo && add_repo
done

for repo_path in "$DOCKER_APP_DIR"/*/; do
    repo=$("$DOCKER_BASE"/repo.sh "$repo_path")
    first_repo || last_repo || add_repo
done

for repo_path in "$DOCKER_APP_DIR"/*/; do
    repo=$("$DOCKER_BASE"/repo.sh "$repo_path")
    last_repo && add_repo
done

cat "$temp"
finish
