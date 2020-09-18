#!/bin/bash

basedir=$(dirname "$1")
repo="$2"
shift 2

pushd "$basedir/$repo" || exit

docker image build -t build .
container=$(docker container create build)

temp=$(mktemp -d)
docker container cp "$container":/docker4gis "$temp"
docker container rm -f "$container"
docker image rm build

"$temp"/docker4gis/build.sh .

rm -rf "$temp"

popd || exit
