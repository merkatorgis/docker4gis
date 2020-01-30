#!/bin/bash

PLSH_ISH="${PLSH_ISH:-bae6f78}"

apk add --no-cache --virtual .build-deps \
	g++ make

here=$(dirname "$0")
archive="${here}/plsh-${PLSH_ISH}.zip"
src_dir=$(mktemp -d)
echo A | unzip "${archive}" -d "${src_dir}"

pushd "${src_dir}"
make
make install
popd

apk del .build-deps

rm -rf "${src_dir}" "${here}"
