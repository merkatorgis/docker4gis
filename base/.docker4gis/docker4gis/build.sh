#!/bin/bash

DOCKER_BASE=$DOCKER_BASE
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_REPO=$DOCKER_REPO

repo=$DOCKER_REPO

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

buildscript=./build.sh
# Ensure we have something to run.
x "$buildscript"

# Find any Dockerfile to read the FROM clause from.
dockerfile=Dockerfile
[ -f "$dockerfile" ] ||
    dockerfile=dockerfile

# Parse the Dockerfile's FROM clause.
# sed:
# -n: silent; do not print the whole (modified) file
# 's~regex~\groupno~ip':
#   p: do print what's found
#   i: ignore case
[ -f "$dockerfile" ] &&
    docker4gis_base_image=$(sed -n 's~^FROM\s\+\(docker4gis/\S\+\).*~\1~ip' "$dockerfile" | tail -n 1)

# Note that "$docker4gis_base_image" may be unset even if "$dockerfile" isn't,
# since building from a non-docker4gis base image is anything but abnormal.
if [ "$docker4gis_base_image" ]; then
    # When we're extending a docker4gis generic image, then set the BASE
    # variable, so that the extending build script can run "$BASE"/build.sh.
    dotdocker4gis=$(dirname "$0")/.docker4gis.sh
    x "$dotdocker4gis"
    BASE=$("$dotdocker4gis" "$temp" "$docker4gis_base_image") || finish 1
    x "$BASE"/build.sh
    export BASE
fi

[ "$repo" = .package ] && repo=package
IMAGE=$DOCKER_REGISTRY/$DOCKER_USER/$repo:latest
export IMAGE
echo
echo "Building $IMAGE"

[ "$DOCKER_USER" = docker4gis ] || {
    # When building a concrete application's component or package image, as
    # opposed to a docker4gis generic component image, remove any existing
    # container, so that it gets replaced by a new one, started from the new
    # image we're going to build now.
    [ "$repo" = proxy ] &&
        container=docker4gis-proxy ||
        container=$DOCKER_USER-$repo
    docker container stop "$container" >/dev/null 2>&1
    docker container rm "$container" >/dev/null 2>&1
}

# Ensure a conf directory for the Dockerfile to ADD or COPY from, and provision
# it temporarily with the .docker4gis and .plugins directories.
mkdir -p conf
DOCKER_BASE=$(npx --yes docker4gis@"${DOCKER4GIS_VERSION:-latest}" base)
cp -r "$DOCKER_BASE"/.plugins "$DOCKER_BASE"/.docker4gis conf

# Execute the actual build script,
# which may or may not execute "$BASE"/build.sh,
# which may or may not be set.
"$buildscript" "$@"
result=$?

# Clean up the temporary conf content.
rm -rf conf/.plugins conf/.docker4gis

finish "$result"
