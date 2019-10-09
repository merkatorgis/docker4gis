#!/bin/bash

OGR_FDW_VERSION="${OGR_FDW_VERSION:-1.0.5}"

echo '@edge http://dl-3.alpinelinux.org/alpine/edge/main
http://dl-3.alpinelinux.org/alpine/edge/community
http://dl-3.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories

# WARNING: This apk-tools is OLD! Some packages might not function properly.
apk update 2>/dev/null
# WARNING: This apk-tools is OLD! Some packages might not function properly.
apk add --upgrade apk-tools@edge 2>/dev/null

apk add --no-cache --virtual .build-deps \
	make cmake g++ \
	gdal-dev unixodbc-dev \
	postgresql-dev

here=$(dirname "$0")
# archive="https://github.com/pramsey/pgsql-ogr-fdw/archive/v${OGR_FDW_VERSION}.tar.gz"
archive="${here}/pgsql-ogr-fdw-${OGR_FDW_VERSION}.tar.gz"
src_dir=$(mktemp -d)

tar --extract \
    --file "${archive}" \
    --directory "${src_dir}" \
	--strip-components 1
pushd "${src_dir}"
make
make install
popd
rm -rf "${src_dir}" "${here}"

apk del .build-deps
