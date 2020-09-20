#!/bin/bash
set -e

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

pushd "$(dirname "$0")"
    base_image=$(./image.sh "$dir")
    ./base.sh "$dir" "$base_image"
popd
export BASE="$dir"/.docker4gis/build.sh

# Execute the actual build script, which may or may not execute $BASE,
# and ensure that we survive, to remain able to clean up.
if pushd "$dir" && "$buildscript" "$@" && popd; then
    true
fi

if [ -d "$dir"/.docker4gis ]; then
    rm -rf "$dir"/.docker4gis
fi
