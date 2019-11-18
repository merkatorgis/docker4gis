#!/bin/bash

# ODBC_FDW_VERSION="${ODBC_FDW_VERSION:-0.3.0}"
ODBC_FDW_VERSION="${ODBC_FDW_VERSION:-e4d5fe8}"

apk add --no-cache --virtual .build-deps \
	make cmake g++ unixodbc-dev postgresql-dev

here=$(dirname "$0")
# archive="https://github.com/CartoDB/odbc_fdw/archive/${ODBC_FDW_VERSION}.tar.gz"
#archive="${here}/odbc_fdw-${ODBC_FDW_VERSION}.tar.gz"
archive="${here}/odbc_fdw-${ODBC_FDW_VERSION}.zip"
src_dir=$(mktemp -d)

# tar --extract \
#     --file "${archive}" \
#     --directory "${src_dir}" \
# 	--strip-components 1
unzip "${archive}" -d "${src_dir}"
#pushd "${src_dir}"
pushd "${src_dir}"/odbc_fdw-*
make
make install
popd

apk del .build-deps

rm -rf "${src_dir}" "${here}"
