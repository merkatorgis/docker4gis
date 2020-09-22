#!/bin/bash
# set -x

DOCKER_BASE="$DOCKER_BASE"
DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="${DOCKER_USER:-docker4gis}"

repo=$(basename "$(pwd)")
image="$DOCKER_REGISTRY""$DOCKER_USER"/package

mkdir -p conf

if [ "$repo" = .package ]; then
    # we're building a concrete application's package image;
    # compile a list of commands to run its containers
    echo '#!/bin/bash' >conf/run.sh
    # echo 'set -x' >>conf/run.sh
    # echo 'find .' >>conf/run.sh
    chmod +x conf/run.sh
    first_repo() {
        local first
        local repo
        repo=$(basename "$repo_path")
        # run database containers before any database-querying containers
        for first in postgis mysql; do
            [ "$first" = "$repo" ] && return 0
        done
        return 1
    }
    add_repo() {
        # read tag from tag file
        local tag
        tag=$(cat "$repo_path"/tag 2>/dev/null) || tag=latest
        local repo
        repo=$(basename "$repo_path")
        echo ".docker4gis/base/run.sh $repo $tag" >>conf/run.sh
    }
    # loop over all repos to add, picking the ones we want to do first
    for repo_path in ../*/; do
        first_repo && add_repo
    done
    # loop over all repos to add, skipping the ones we just did
    for repo_path in ../*/; do
        first_repo || add_repo
    done
fi

cp -r "$DOCKER_BASE"/.docker4gis conf
docker image build \
    -t "$image" .

rm -rf conf
