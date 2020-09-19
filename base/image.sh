#!/bin/bash

dir="$1"

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
sed -n 's~^FROM\s\+\(docker4gis/\S\+\).*~\1~ip' "$dockerfile"
