#!/bin/bash

dir=$1
docker4gis_image=$2

# Copy the /.docker4gis directory out of the given image,
# to the given directory,
# by creating a temporary container from the image.
mkdir -p "$dir" &&
    container=$(docker container create "$docker4gis_image") &&
    docker container cp "$container":/.docker4gis "$dir"

docker container rm "$container" >/dev/null

if [ -d "$dir"/.docker4gis ]; then
    echo "$dir"/.docker4gis
else
    echo "/.docker4gis directory not written from image '$docker4gis_image'" >&2
    exit 1
fi
