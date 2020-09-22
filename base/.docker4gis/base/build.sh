#!/bin/bash
# set -x

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
    $("$survive") && return 1 || fail "$message"
}

executable() {
    local file="$1"
    survive="${2:-false}"
    [ -x "$file" ] && echo "$file" || failed "Executable not found: $file."
}

file() {
    local file="$1"
    survive="${2:-false}"
    [ -f "$file" ] && echo "$file" || failed "File not found: $file."
}

# Ensure we have something to do.
buildscript=$(executable "$dir/build.sh")

# Find the Dockerfile to read the FROM clause from.
dockerfile=$(file "$dir"/Dockerfile "true") ||
    dockerfile=$(file "$dir"/dockerfile "false")

docker4gis() {
    docker4gis="$(dirname "$0")"/.docker4gis.sh
    docker4gis_dir=$("$docker4gis" "$dir" "$docker4gis_base_image")
    # The $buildscript probably wants to mainly execute the "$BASE" script.
    export BASE="$docker4gis_dir"/build.sh
    executable "$BASE"
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

# Execute the actual build script,
# which may or may not execute "$BASE",
# which may or may not be set.
pushd "$dir" >/dev/null
"$buildscript" "$@" >&1
popd >/dev/null

# Clean up, if needed.
[ -d "$docker4gis_dir" ] && rm -rf "$docker4gis_dir"
