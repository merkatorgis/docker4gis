#!/bin/bash
set -e

DOCKER_BASE="$DOCKER_BASE"

mainscript="$1"
repo="$2"
shift 2

dir=$(dirname "$mainscript")/"$repo"
dir=$(realpath "$dir")

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
    exit 2
fi

# sed:
# -n: silent; do not print the whole (modified) file
# 's~regex~\groupno~ip':
#   p: do print what's found
#   i: ignore case
docker4gis_base_image=$(sed -n 's~^FROM\s\+\(docker4gis/\S\+\)~\1~ip' "$dockerfile")
base_dir="$dir"/.docker4gis

"$DOCKER_BASE"/base.sh "$base_dir" "$docker4gis_base_image"
export BASE="$base_dir"/build.sh

# Execute the actual build script, which may or may not execute $BASE,
# and ensure that we survive, to remain able to clean up.
if pushd "$dir" && "$buildscript" "$@" && popd; then
    true
fi

if [ -d "$base_dir" ]; then
    rm -rf "$base_dir"
fi
