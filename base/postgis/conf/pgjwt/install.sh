#!/bin/bash

PGJWT_ISH="${PGJWT_ISH:-0f1aa16}"

apk add --no-cache --virtual .build-deps \
	openssh make

here=$(dirname "$0")
archive="${here}/pgjwt-${PGJWT_ISH}.zip"
src_dir=$(mktemp -d)
echo A | unzip "${archive}" -d "${src_dir}"

pushd "${src_dir}"
make install
popd

apk del .build-deps

rm -rf "${src_dir}" "${here}"
