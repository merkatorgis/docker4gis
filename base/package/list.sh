#!/bin/bash

# compiles a list of commands to run all repos' containers

# Either empty (we're creating the package image's run.sh script from the
# build.sh), or 'dirty' (we're running without a package image, from a component
# or package repo in the dev env).
directive=$1

BASE=$BASE
DOCKER_BASE=$DOCKER_BASE
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER

temp_components=$(mktemp -d)
package_dir_container=$(mktemp)
output=$(mktemp)

finish() {
    rm -rf "$temp_components"
    rm -f "$package_dir_container"
    rm -f "$output"
    exit "${1:-0}"
}

error() {
    echo "> ERROR: $1" >&2
    finish 1
}

# In the dev env, component repos should be found as sibblings of the current directory.
for file in ../*/build.sh; do
    [ -f "$file" ] || break
    dir=$(dirname "$file")
    if [ -f "$dir"/.env ]; then
        (
            DOCKER_REPO=
            # shellcheck source=/dev/null
            . "$dir"/.env
            # If there's a build.sh, a .env and a DOCKER_REPO, then it must
            # be a docker4gis repo directory.
            [ "$DOCKER_REPO" ] && {
                version=latest
                version_file="$dir"/version
                if [ -f "$version_file" ]; then
                    version=$(cat "$version_file")
                fi
                if [ "$DOCKER_REPO" = package ]; then
                    # Just remember that this was the package directory.
                    echo "$dir" >"$package_dir_container"
                else
                    [ "$version" = latest ] || {
                        # If the version was updated (to something other than
                        # "latest"), then apparently the image was pushed. Since
                        # that could have been done by the pipeline (out of our
                        # sight), we might locally have a now unwanted leftover
                        # "latest" image.
                        current_version_file=./components/"$DOCKER_REPO"
                        [ -f "$current_version_file" ] && current_version=$(cat "$current_version_file")
                        if ! [ "$current_version" = "$version" ]; then
                            image=$DOCKER_REGISTRY/$DOCKER_USER/$DOCKER_REPO
                            docker image rm -f "$image":latest >/dev/null 2>&1
                        fi
                    }
                    # Add this repo's version to the list of components.
                    echo "$version" >"$temp_components"/"$DOCKER_REPO"
                fi
            }
        )
    fi
done
components=./components
# Replace the current components list with the new list. In the pipeline, no
# component sibblings are found, and the current list of components remains.
if ls "$temp_components"/* >/dev/null 2>&1; then
    package_dir=$(cat "$package_dir_container")
    [ -d "$package_dir" ] || error "package directory not found"
    components="$package_dir"/components
    mkdir -p "$components"
    rm -f "$components"/*
    cp "$temp_components"/* "$components"
fi
mkdir -p "$components"

ls "$components"/* >/dev/null 2>&1 || error "nothing to run"

local_image_exists() {
    docker image tag "$1" "$1" >/dev/null 2>&1
}

repo=
version=

add_repo() {

    echo "Fetching $repo..." >&2

    local image=$DOCKER_REGISTRY/$DOCKER_USER/$repo
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
                error "version unknown for '$repo'; was it pushed already?"
            fi
        fi
        # use local image _if_ it exists
        local_image_exists "$image:$tag" ||
            # otherwise, try to find it in the registry
            docker image pull "$image:$tag" >/dev/null ||
            error "image '$image:$tag' not found"
    fi

    if [ "$tag" ]; then
        echo "$BASE/docker4gis/run.sh $repo $tag" >>"$output"
        echo "$image:$tag" >&2
    else
        error "no tag for '$image'"
    fi
}

# Test if current repo is one of the given repos.
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

# Loop through all components and add those that should go first.
for repo_file in "$components"/*; do
    first_repo && add_repo
done

# Loop through all components again and add those that should not go first or
# last.
for repo_file in "$components"/*; do
    first_repo || last_repo || add_repo
done

# Loop through all components again and add those that should go last.
for repo_file in "$components"/*; do
    last_repo && add_repo
done

# Echo the collected commands to run eachcomponent.
cat "$output"

# Tidy up.
finish
