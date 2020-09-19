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

base_dir="$dir"/.docker4gis
base_image=$("$DOCKER_BASE"/image.sh "$dir")

"$DOCKER_BASE"/base.sh "$base_dir" "$base_image"
export BASE="$base_dir"/build.sh

# Execute the actual build script, which may or may not execute $BASE,
# and ensure that we survive, to remain able to clean up.
if pushd "$dir" && "$buildscript" "$@" && popd; then
    true
fi

if [ -d "$base_dir" ]; then
    rm -rf "$base_dir"
fi
