#!/bin/bash

IMAGE=${IMAGE:-docker4gis/$(basename "$(realpath .)")}
DOCKER_BASE=$DOCKER_BASE

build() {
    mkdir -p conf
    cp -r "$DOCKER_BASE"/.plugins "$DOCKER_BASE"/.docker4gis conf
    docker image build \
        -t "$IMAGE" .
    rm -rf conf/.plugins conf/.docker4gis
}

if [ "$1" = maven ] && maven_tag=$2 && src_dir=$(realpath "$3"); then
    DOCKER_REGISTRY='' DOCKER_USER=docker4gis \
        "$BASE"/docker4gis/run.sh maven "$maven_tag" "$src_dir" &&
        (
            webapps=conf/webapps
            mkdir -p "$webapps"
            war_project=$(basename "$src_dir")
            war_file=$webapps/$war_project.war
            cp "$src_dir"/target/*.war "$war_file"
            build
            rm -f "$war_file"
            [ "$(ls "$webapps")" ] || rm -rf "$webapps"
        )
else
    build
fi
