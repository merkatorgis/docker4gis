#!/bin/bash

LIBKML_VERSION="${LIBKML_VERSION:-1.3.0}"
GDAL_VERSION="${GDAL_VERSION:-2.2.4}"

apk add --no-cache \
	expat zlib boost uriparser minizip unixodbc

apk add --no-cache --virtual .build-deps \
	make cmake g++ \
	expat-dev zlib-dev boost-dev uriparser-dev minizip-dev unixodbc-dev

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

archive=$(mktemp)
src_dir=$(mktemp -d)
wget -O "${archive}" "https://github.com/OSGeo/gdal/archive/v${GDAL_VERSION}.tar.gz"
tar --extract \
    --file "${archive}" \
    --directory "${src_dir}" \
	--strip-components 1
pushd "${src_dir}/gdal"
./configure --with-libkml --with-odbc
make
make install
popd
rm -rf "${src_dir}" "${archive}"

apk del .build-deps

rm -rf $(dirname "$0")
