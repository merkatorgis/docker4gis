#!/bin/bash
# set -x

DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="$DOCKER_USER"

mainscript="$1"
repo="$2"
shift 2

dir=$(dirname "$mainscript")/"$repo"
dir=$(realpath "$dir")

fail() {
    echo "$1" >&2
    exit 1
}

failed() {
    local message="$1"
    local survive="$2"
    if [ "$survive" = "true" ]; then
        return 1
    else
        fail "$message"
    fi
}

x() {
    local file="$1"
    local survive="$2"
    if [ -x "$file" ]; then
        echo "$file"
    else
        failed "Executable not found: $file." "$survive"
    fi
}

f() {
    local file="$1"
    local survive="$2"
    if [ -f "$file" ]; then
        echo "$file"
    else
        failed "File not found: $file." "$survive"
    fi
}

# Ensure we have something to do.
buildscript=$(x "$dir/build.sh")

# Find the Dockerfile to read the FROM clause from.
dockerfile=$(f "$dir"/Dockerfile "true") ||
    dockerfile=$(f "$dir"/dockerfile "false")

docker4gis() {
    docker4gis="$(dirname "$0")"/.docker4gis.sh
    docker4gis_dir=$("$docker4gis" "$dir" "$docker4gis_base_image")
    # The $buildscript probably wants to mainly execute the "$BASE" script.
    BASE=$(x "$docker4gis_dir"/build.sh)
    export BASE
}

# Parse the Dockerfile's FROM clause.
# sed:
# -n: silent; do not print the whole (modified) file
# 's~regex~\groupno~ip':
#   p: do print what's found
#   i: ignore case
# Note that "$docker4gis_base_image" can be unset,
# since building from a non-docker4gis base image is anything but abnormal.
docker4gis_base_image=$(sed -n 's~^FROM\s\+\(docker4gis/\S\+\).*~\1~ip' "$dockerfile") &&
    docker4gis

finish() {
    # Clean up, if needed.
    [ -d "$docker4gis_dir" ] && rm -rf "$docker4gis_dir"
    exit "${1:-0}"
}

image="$DOCKER_REGISTRY""$DOCKER_USER"/"$repo":"$tag"
[ "$repo" = proxy ] &&
    container="docker4gis-proxy" ||
    container="$DOCKER_USER"-"$repo"
echo
echo "Building $image"
docker container rm -f "$container" 2>/dev/null

# Execute the actual build script,
# which may or may not execute "$BASE",
# which may or may not be set.
pushd "$dir" >/dev/null || finish 1
"$buildscript" "$@" >&1
popd >/dev/null || finish 1

finish
