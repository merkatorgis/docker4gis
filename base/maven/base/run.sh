#!/bin/bash

src_dir="$1"
maven_tag="${2:-latest}"

echo; echo "Compiling from '${src_dir}'..."

docker volume create mvndata

docker container run --rm \
    -v "${src_dir}":/src \
    --mount source=mvndata,target=/root/.m2 \
    "docker4gis/maven:${maven_tag}"
