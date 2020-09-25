#!/bin/bash

DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER

mainscript=$1
repo=$2
shift 2

dir=$(dirname "$mainscript")/"$repo"
dir=$(realpath "$dir")

temp=$(mktemp -d)
finish() {
    rm -rf "$temp"
    exit "${1:-$?}"
}

fail() {
    echo "$1" >&2
    finish 1
}

failed() {
    local message=$1
    local survive=$2
    if [ "$survive" = "true" ]; then
        return 1
    else
        fail "$message"
    fi
}

x() {
    local file=$1
    local survive=$2
    if [ -x "$file" ]; then
        echo "$file"
    else
        failed "Executable not found: '$file'." "$survive"
    fi
}

f() {
    local file=$1
    local survive=$2
    if [ -f "$file" ]; then
        echo "$file"
    else
        failed "File not found: '$file'." "$survive"
    fi
}

# Ensure we have something to do.
buildscript=$(x "$dir/build.sh")

# Find the Dockerfile to read the FROM clause from.
dockerfile=$(f "$dir"/Dockerfile "true") ||
    dockerfile=$(f "$dir"/dockerfile "false")

# Parse the Dockerfile's FROM clause.
# sed:
# -n: silent; do not print the whole (modified) file
# 's~regex~\groupno~ip':
#   p: do print what's found
#   i: ignore case
# Note that "$docker4gis_base_image" can be unset,
# since building from a non-docker4gis base image is anything but abnormal.
if docker4gis_base_image=$(sed -n 's~^FROM\s\+\(docker4gis/\S\+\).*~\1~ip' "$dockerfile"); then
    dotdocker4gis=$(x "$(dirname "$0")"/.docker4gis.sh)
    BASE=$("$dotdocker4gis" "$temp" "$docker4gis_base_image")
    export BASE
    x "$BASE"/build.sh >/dev/null
fi

[ "$repo" = .package ] &&
    IMAGE=$DOCKER_REGISTRY$DOCKER_USER/package ||
    IMAGE=$DOCKER_REGISTRY$DOCKER_USER/$repo
export IMAGE
echo
echo "Building $IMAGE"

[ "$repo" = proxy ] &&
    container=docker4gis-proxy ||
    container=$DOCKER_USER-$repo
docker container rm -f "$container" >/dev/null 2>&1

# Execute the actual build script,
# which may or may not execute "$BASE"/build.sh,
# which may or may not be set.
pushd "$dir" >/dev/null || finish 1
"$buildscript" "$@"
popd >/dev/null || finish 1

finish
