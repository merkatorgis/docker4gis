#!/bin/bash

# version possibly includes a "flavour" suffix.
version=${1:?"version parameter not set"}

# tag is the "bare" version, which is also used for the git tag.
tag=${2:-$version}

DOCKER_REPO=${DOCKER_REPO:-$(basename "$(realpath .)")}
from="FROM docker4gis/$DOCKER_REPO"

replace() {
    sed -i "s|$1|$2|ig" "$dockerfile"
}

# -mindepth 2 to skip the Dockerfile in the current directory.
find . -mindepth 2 -name Dockerfile | while read -r dockerfile; do
    # Note that this makes it okay to commit template Dockerfiles with a
    # _latest_ tag (FROM docker4gis/$DOCKER_REPO:latest), which is probably how
    # you were testing extensions of your newly built base component image.

    # Use the (possibly "flavoured") version for the proper component image.
    replace "$from:.*" "$from:$version"

    # Use the "bare" version for any sub image (note the "-").
    replace "$from-\(.*\):\S\+" "$from-\1:$tag"
done
