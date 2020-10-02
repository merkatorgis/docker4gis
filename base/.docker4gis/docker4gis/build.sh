#!/bin/bash

DOCKER_BASE=$DOCKER_BASE
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_APP_DIR=$DOCKER_APP_DIR

repo=$1
shift 1

dir=$DOCKER_APP_DIR/$repo

if [ "$repo" = .package ] && ! [ -d "$dir" ]; then
    # Install the .package template.
    cp -r "$DOCKER_BASE"/../templates/.package "$DOCKER_APP_DIR" &&
        echo "> Package component installed; remember to commit changes."
fi

temp=$(mktemp -d)
finish() {
    local code=$1
    local message=$2
    [ "$message" ] && echo "$message" >&2
    rm -rf "$temp"
    exit "${code:-$?}"
}

x() {
    [ -x "$1" ] || finish 1 "Executable not found: '$1'."
}

buildscript=$dir/build.sh
# Ensure we have something to run.
x "$buildscript"

# Find any Dockerfile to read the FROM clause from.
dockerfile="$dir"/Dockerfile
[ -f "$dockerfile" ] ||
    dockerfile="$dir"/dockerfile

# Parse the Dockerfile's FROM clause.
# sed:
# -n: silent; do not print the whole (modified) file
# 's~regex~\groupno~ip':
#   p: do print what's found
#   i: ignore case
[ -f "$dockerfile" ] &&
    docker4gis_base_image=$(sed -n 's~^FROM\s\+\(docker4gis/\S\+\).*~\1~ip' "$dockerfile" | head -n 1)

# Note that "$docker4gis_base_image" may be unset even if "$dockerfile" isn't,
# since building from a non-docker4gis base image is anything but abnormal.
if [ "$docker4gis_base_image" ]; then
    dotdocker4gis=$(dirname "$0")/.docker4gis.sh
    x "$dotdocker4gis"
    BASE=$("$dotdocker4gis" "$temp" "$docker4gis_base_image") || finish 1
    x "$BASE"/build.sh
    export BASE
fi

[ "$repo" = .package ] && repo=package
IMAGE=$DOCKER_REGISTRY$DOCKER_USER/$repo:latest
export IMAGE
echo
echo "Building $IMAGE"

[ "$repo" = proxy ] &&
    container=docker4gis-proxy ||
    container=$DOCKER_USER-$repo
# Remove any existing container, so that it gets replaced by a new one,
# started from the new image we're going to build now.
docker container rm -f "$container" >/dev/null 2>&1

# Execute the actual build script,
# which may or may not execute "$BASE"/build.sh,
# which may or may not be set.
pushd "$dir" >/dev/null || finish 1
"$buildscript" "$@"
result=$?
popd >/dev/null || finish 1

finish "$result"
