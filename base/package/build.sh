#!/bin/bash

[ "$IMAGE" ] && extension=true
IMAGE=${IMAGE:-docker4gis/$(basename "$(realpath .)")}
DOCKER_BASE=$DOCKER_BASE
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER

mkdir -p conf

if [ "$extension" ]; then
    # we're building a concrete application's package image;
    # compile a list of commands to run its containers
    echo '#!/bin/bash' >conf/run.sh
    # echo 'set -x' >>conf/run.sh
    # echo 'find .' >>conf/run.sh
    chmod +x conf/run.sh
    here=$(realpath "$(dirname "$0")")
    # shellcheck disable=SC2016
    (
        cd ..
        BASE='' "$here"/list.sh
    ) >>conf/run.sh || exit 1
fi

cp -r "$DOCKER_BASE"/.docker4gis conf
docker image build \
    --build-arg DOCKER_USER="$DOCKER_USER" \
    --build-arg DOCKER_REGISTRY="$DOCKER_REGISTRY" \
    -t "$IMAGE" .

rm -rf conf
