#!/bin/bash

apk add --no-cache --virtual .build-deps \
    alpine-sdk py-setuptools

pgxn install safeupdate

echo "shared_preload_libraries=safeupdate" \
    >>/etc/postgresql/postgresql.conf

apk del .build-deps
