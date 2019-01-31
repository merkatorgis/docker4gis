#!/bin/bash
set -e

src_dir="${1}"

echo; echo "Building ${src_dir}"

pushd "${src_dir}"
echo 'FROM merkatorgis/elm-app' > ./Dockerfile
docker image build -t elm-app/build .
rm ./Dockerfile
popd

mkdir -p build
docker container run \
    --rm \
    -v $PWD/build:/app/build \
    elm-app/build
docker image rm elm-app/build


here=$(dirname "$0")

"${here}/../serve/build.sh" "$(pwd)/build"

rm -rf build
