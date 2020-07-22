#!/bin/bash

action=${1:-build}
tag=$2

_push() {
    local component=$1
    local tag=$2
    docker image tag "docker4gis/$component:latest" "docker4gis/$component:$tag" &&
        echo "pushing $component:$tag..." &&
        if docker image push "docker4gis/$component:$tag" >/dev/null; then
            echo "$component:$tag"
        else
            echo "FAILED: $component:$tag"
        fi
}

push() {
    local component=$1
    local extra=$2
    _push "$component" latest &
    _push "$component" "$tag" &
    if [ "$extra" ]; then
        _push "$component" "$extra" &
    fi
    wait
}

build() {
    local component=$1
    (
        cd "$DOCKER_BASE"/"$component" &&
            echo "building $component..." &&
            if ./build.sh >/dev/null 2>&1; then
                echo "$component"
            else
                echo "FAILED: $component"
            fi
    )
}

if [ "$action" = 'build' ]; then
    (build tomcat &&
        build geoserver) &
    (build postgis &&
        build cron) &
    build proxy &
    build postfix &
    build mysql &
    wait
elif [ "$action" = 'push' ] && [ "$tag" -eq "$tag" ]; then
    push tomcat &
    push geoserver &
    push postgis 11 &
    push cron &
    push proxy &
    push postfix &
    push mysql &
    wait
fi
