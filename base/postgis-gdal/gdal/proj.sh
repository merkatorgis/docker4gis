#!/bin/bash

PROJ_VERSION="${PROJ_VERSION}"
PROJ_DATUMGRID_VERSION="${PROJ_DATUMGRID_VERSION}"

apk add --no-cache \
	sqlite sqlite-doc

apk add --no-cache --virtual .build-deps2 \
	sqlite-dev sqlite-libs

archive=$(mktemp)
src_dir=$(mktemp -d)
wget -O "${archive}" "https://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz"
tar --extract \
    --file "${archive}" \
    --directory "${src_dir}" \
	--strip-components 1
pushd "${src_dir}"
./configure
wget "https://download.osgeo.org/proj/proj-datumgrid-${PROJ_DATUMGRID_VERSION}.zip"
echo A | unzip "proj-datumgrid-${PROJ_DATUMGRID_VERSION}.zip" -d data
make
make install
popd
rm -rf "${src_dir}" "${archive}"
