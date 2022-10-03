#!/bin/bash

# compiles a list of commands to run all repos' containers

directive=$1

BASE=$BASE
DOCKER_BASE=$DOCKER_BASE
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER

temp_components=$(mktemp -d)
base_dir_container=$(mktemp)
temp=$(mktemp)

finish() {
    rm -rf "$temp_components"
    rm -f "$base_dir_container"
    rm -f "$temp"
    exit "${1:-0}"
}

error() {
    echo "> ERROR: $1" >&2
    finish 1
}

# In the dev env, component repos should be found as sibblings of the base repo.
for file in ../*/build.sh; do
    dir=$(dirname "$file")
    if [ -f "$dir"/.env ]; then
        version=latest
        version_file="$dir"/version
        if [ -f "$version_file" ]; then
            version=$(cat "$version_file")
        fi
        (
            # shellcheck source=/dev/null
            . "$dir"/.env
            if [ "$DOCKER_REPO" = base ]; then
                echo "$dir" >"$base_dir_container"
            else
                echo "$version" >"$temp_components"/"$DOCKER_REPO"
            fi
        )
    fi
done
components=./components
# Replace the current components list with the new list. In the pipeline, no
# component sibblings are found, and the current list of components remains.
if ls "$temp_components"/* >/dev/null 2>&1; then
    base_dir=$(cat "$base_dir_container")
    [ -d "$base_dir" ] || error "base directory not found"
    components="$base_dir"/components
    mkdir -p "$components"
    rm -f "$components"/*
    cp "$temp_components"/* "$components"
fi
mkdir -p "$components"

local_image_exists() {
    docker image tag "$1" "$1" >/dev/null 2>&1
}

repo=
version=

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
        if ! [ "$version" = latest ]; then
            tag=$version
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

pick_repo() {
    repo=$(basename "$repo_file")
    version=$(cat "$repo_file")
    local item
    for item in "$@"; do
        [ "$item" = "$repo" ] && return 0
    done
    return 1
}

first_repo() {
    pick_repo postgis mysql
}

last_repo() {
    pick_repo proxy
}

for repo_file in "$components"/*; do
    first_repo && add_repo
done

for repo_file in "$components"/*; do
    first_repo || last_repo || add_repo
done

for repo_file in "$components"/*; do
    last_repo && add_repo
done

cat "$temp"
finish
