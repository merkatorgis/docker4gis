#!/bin/bash
set -e

DOCKER_BASE="$DOCKER_BASE"
DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="${DOCKER_USER:-docker4gis}"

repo=$(basename "$(pwd)")
image="$DOCKER_REGISTRY""$DOCKER_USER"/package

echo
echo "Building $image"

mkdir -p conf
if [ "$repo" = .package ]; then
    echo '#!/bin/bash' >conf/run.sh
    chmod +x conf/run.sh
    for repo in ../*/; do
        if ! tag=$(cat "$repo"/tag); then
            tag=latest
        fi
        repo=$(basename "$repo")
        echo ".docker4gis/base/run.sh $repo $tag" >>conf/run.sh
    done
fi
cp -r "$DOCKER_BASE"/utils conf
docker image build \
    -t "$image" .
rm -rf conf
