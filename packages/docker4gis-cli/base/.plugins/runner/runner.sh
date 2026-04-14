#!/bin/bash

# set -x

# In some cases, we're run from an "empty" environment. In that case, a
# workaround to get the DOCKER_USER value is to run a thus-named copy of this
# script.
export DOCKER_USER=${DOCKER_USER:-$(basename "$0")}

script_path=$(which "$1") || {
    echo "No executable command: $1"
    exit 127
}
shift 1

file=/runner/$(whoami)$script_path
dir=$(dirname "$file")
mkdir -p "$dir"

days=${DOCKER4GIS_RUNNER_DAYS:-90}
[ -f "$file.days" ] ||
    echo "# Number of days to keep log files:
$days" >"$file.days"
# Read the number of days from the file, skipping lines starting with a #.
days=$(grep -v '^#' "$file.days")
# Test if $days is a number.
[[ $days =~ ^[0-9]+$ ]] || {
    echo "Invalid number of days: $days"
    exit 1
}

# Delete files older than $days days.
script_name=$(basename "$script_path")
find "$dir" -name "$script_name.*" ! -name "$script_name.days" -mtime "+$days" -delete

log_file="$file.$(date -I).log"

echo "$$ > $(date -Ins)" >>"$log_file"
"$script_path" "$@" >>"$log_file" 2>&1
result=$?

echo "$$ < $(date -Ins)" >>"$log_file"
exit "$result"
