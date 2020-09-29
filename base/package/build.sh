#!/bin/bash

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
    here=$(realpath "$(dirname "$0")")
    # shellcheck disable=SC2016
    (
        cd ..
        BASE='"$(dirname "$0")"' "$here"/list.sh
    ) >>conf/run.sh || exit 1
fi

cp -r "$DOCKER_BASE"/.docker4gis conf
docker image build \
    -t "$IMAGE" .

rm -rf conf
