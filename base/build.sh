#!/bin/bash
set -ex

mainscript="$1"
repo="$2"
shift 2

dir="$(dirname "$mainscript")/$repo"
dir="$(realpath "$dir")"

buildscript="$dir/build.sh"
if ! [ -x "$buildscript" ]; then
    echo "No executable $buildscript found"
    exit 1
fi

dockerfile="$dir/Dockerfile"
if ! [ -f "$dockerfile" ]; then
    dockerfile="$dir/dockerfile"
fi
if ! [ -f "$dockerfile" ]; then
    echo 'Dockerfile not found'
    exit 1
fi

# sed:
# -n: silent; do not print the whole (modified) file
# 's~regex~\groupno~ip':
#   p: do print what's found
#   i: ignore case
docker4gis_base_image=$(sed -n 's~^from\s\+\(docker4gis/\S\+\)~\1~ip' "$dockerfile")
if [ "$docker4gis_base_image" ]; then
    container=$(docker container create "$docker4gis_base_image")

    temp=$(mktemp -d)
    docker container cp "$container":/docker4gis "$temp"
    docker container rm -f "$container"

    export BASE_BUILD="$temp/docker4gis/build.sh"
    if ! [ -x "$BASE_BUILD" ]; then
        echo "No executable $BASE_BUILD found"
    fi
fi

# Execute the actual build script, which may or may not execute $BASE_BUILD,
# and ensure that we survive, to be able to clean up $temp
if pushd "$dir" && "$buildscript" && popd; then
    true
fi

if [ "$temp" ]; then
    rm -rf "$temp"
fi
