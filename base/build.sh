#!/bin/bash

# this is just a tool for development of docker4gis features

for component in "$@"; do
    dir=$(realpath "$component")
    (cd "$dir" && ./build.sh) &
done
wait
