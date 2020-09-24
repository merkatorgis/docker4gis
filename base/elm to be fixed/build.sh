#!/bin/bash
set -e

src_dir="${1}"

shift 1
includes="${@}"

echo; echo "Building ${src_dir}"

pushd "${src_dir}"
echo 'FROM docker4gis/elm-app:214' > ./Dockerfile
docker image build -t elm-app/build .
rm ./Dockerfile
popd

mkdir -p build
docker container run \
    --rm \
	-v "$(docker_bind_source "${PWD}/build")":/app/build \
    elm-app/build
docker image rm elm-app/build

cp -r "${includes}" build/

here=$(dirname "$0")

"${here}/../serve/build.sh" build/ --single

rm -rf build/
