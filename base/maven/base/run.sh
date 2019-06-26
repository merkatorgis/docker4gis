#!/bin/bash

src_dir="$1"

echo; echo "Compiling from '${src_dir}'..."

docker volume create mvndata

docker container run --rm \
    -v "${src_dir}":/src \
    --mount source=mvndata,target=/root/.m2 \
    docker4gis/maven
