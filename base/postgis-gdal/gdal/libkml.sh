#!/bin/bash

LIBKML_VERSION="${LIBKML_VERSION}"

archive=$(mktemp)
src_dir=$(mktemp -d)
wget -O "${archive}" "https://github.com/libkml/libkml/archive/${LIBKML_VERSION}.tar.gz"
tar --extract \
    --file "${archive}" \
    --directory "${src_dir}" \
	--strip-components 1
mkdir "${src_dir}/build"
pushd "${src_dir}/build"
cmake ..
make
make install
popd
rm -rf "${src_dir}" "${archive}"
