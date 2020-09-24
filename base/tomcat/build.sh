#!/bin/bash

DOCKER_BASE="$DOCKER_BASE"
DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="${DOCKER_USER:-docker4gis}"

repo=$(basename "$(pwd)")
image="$DOCKER_REGISTRY""$DOCKER_USER"/"$repo"

if [ "$1" = maven ]; then
    tag="$2"
    src_dir=$(realpath "$3")
    if
        DOCKER_USER=docker4gis "$BASE"/docker4gis/run.sh \
            maven "$tag" "$src_dir"
    then
        webapps=conf/webapps
        mkdir -p "$webapps"
        war_project=$(basename "$src_dir")
        war_file="$webapps"/"$war_project".war
        cp "$src_dir"/target/*.war "$war_file"
    fi
fi

mkdir -p conf
cp -r "$DOCKER_BASE"/plugins "$DOCKER_BASE"/.docker4gis conf
docker image build \
    -t "$image" .
rm -rf conf/plugins conf/.docker4gis

if [ "$1" = maven ]; then
    rm -f "$war_file"
    [ "$(ls "$webapps")" ] || rm -rf "$webapps"
fi
