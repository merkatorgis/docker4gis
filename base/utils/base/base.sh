#!/bin/bash
set -e

dir="$1"
docker4gis_image="$2"

if [ "$docker4gis_image" ]; then
    mkdir -p "$dir"
    container=$(docker container create "$docker4gis_image")
    docker container cp "$container":/.docker4gis "$dir"
    docker container rm "$container"
fi
