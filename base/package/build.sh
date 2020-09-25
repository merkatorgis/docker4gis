#!/bin/bash

package_tag=$1
[ "$IMAGE" ] && extension=true
IMAGE=${IMAGE:-docker4gis/$(basename "$(realpath .)")}
DOCKER_BASE=$DOCKER_BASE

mkdir -p conf

if [ "$extension" ]; then
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
        local tag=latest
        # if building a versioned package, read repo's tag from tag file
        [ "$package_tag" ] && [ -f "$repo_path"/tag ] &&
            tag=$(cat "$repo_path"/tag)
        local repo
        repo=$(basename "$repo_path")
        # shellcheck disable=SC2016
        echo '"$(dirname "$0")"'"/docker4gis/run.sh $repo $tag" >>conf/run.sh
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
    -t "$IMAGE" .

rm -rf conf
