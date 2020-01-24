#!/bin/bash

PGXN_VERSION="${PGXN_VERSION:-1.3}"

apk add --no-cache --virtual .build-deps \
	py-setuptools

here=$(dirname "$0")
archive="${here}/pgxnclient-${PGXN_VERSION}.tar.gz"
src_dir=$(mktemp -d)

tar --extract \
    --file "${archive}" \
    --directory "${src_dir}" \
	--strip-components 1

pushd "${src_dir}"
python setup.py install
popd

rm -rf "${src_dir}" "${here}"

apk del .build-deps
