#!/bin/bash

GDAL_VERSION="${GDAL_VERSION}"

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
