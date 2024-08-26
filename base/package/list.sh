#!/bin/bash

# Uncomment for debugging the commands that are issued:
# echo
# echo " -- $0 $* --"
# echo
# set -x

# Compiles a list of commands to run all repos' containers.

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

finish() {
    rm -rf "$temp_components"
    rm -f "$package_dir_container"
    exit "${1:-0}"
}

error() {
    echo "> ERROR: $1" >&2
    finish 1
}

# In the dev env, component repos should be found as siblings of the current
# directory.
for dotenv in ../*/.env; do
    # Break when there's none.
    [ -f "$dotenv" ] || break
    # Start a subshell to prevent overwriting environment variables.
    (
        DOCKER4GIS_VERSION=
        DOCKER_REGISTRY=
        DOCKER_USER=
        DOCKER_REPO=
        # shellcheck source=/dev/null
        . "$dotenv"
        # If this is a docker4gis repo directory, it must have these variables
        # set. Otherwise, exit the subshell (which happens to be the last thing
        # in the for loop).
        [ "$DOCKER4GIS_VERSION" ] && [ "$DOCKER_REGISTRY" ] && [ "$DOCKER_USER" ] && [ "$DOCKER_REPO" ] || exit

        dir=$(dirname "$dotenv")

        packagejson=$dir/package.json
        [ -f "$packagejson" ] || exit
        version=$(node --print "require('$packagejson').version")
        if [ "$version" = 0.0.0 ]; then
            version=latest
        else
            version=v$version
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
    )
done

components=./components
# Replace the current components list with the new list. In the pipeline, no
# component siblings are found, and the current list of components remains.
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
        # Use local image _if_ it exists.
        local_image_exists "$image:$tag" ||
            # Otherwise, try to find it in the registry. Note that this is why
            # the build validation pipeline of the package repo has to log into
            # the docker registry.
            docker image pull "$image:$tag" >/dev/null ||
            error "image '$image:$tag' not found"
    fi

    if [ "$tag" ]; then
        echo "$image:$tag" >&2
        echo >&2
        # Use .docker4gis.sh to copy the image's own version of docker4gis out
        # of the image.
        echo "
            temp=\$(mktemp -d)
            dotdocker4gis=$BASE
            dotdocker4gis=\${dotdocker4gis:-\$(dirname \"\$0\")}
            dotdocker4gis=\$(\"\$dotdocker4gis\"/docker4gis/.docker4gis.sh \$temp '$image:$tag')
            (
                cd \"\$dotdocker4gis\"
                docker4gis/run.sh '$repo' '$tag'
            ) && result=\$?
            rm -rf \$temp
            [ \"\$result\" = 0 ] || exit \"\$result\"
            echo
        "
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
    pick_repo proxy cron
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

# Tidy up.
finish
