#!/bin/bash

apk add --no-cache --virtual .build-deps \
	py-setuptools make gcc libc-dev

pgxn install safeupdate

echo "shared_preload_libraries=safeupdate" \
    >> /etc/postgresql/postgresql.conf

apk del .build-deps
