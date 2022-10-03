#!/bin/bash

# read the repo name from a component directory name

dir=${1:-$PWD}
dir=$(realpath "$dir")
dir=$(basename "$dir")

# up until first . character, if any
repo=${dir%%.*}

echo "$repo"
