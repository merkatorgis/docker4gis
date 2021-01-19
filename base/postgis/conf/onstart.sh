#!/bin/bash

# clear the "last" file (see last.sh)
echo '' >/last

while ! update-postgis.sh; do
    sleep 1
done

pg.sh -c "alter database ${POSTGRES_DB} set app.ddl_done to false"

echo "Next CREATE EXTENSION command will fail for PostGIS < 3."
echo "It's OK to ignore that error."
pg.sh -c "create extension if not exists postgis_raster"

pg.sh -c "create extension if not exists ogr_fdw"
pg.sh -c "create extension if not exists odbc_fdw"
pg.sh -c "create extension if not exists plsh"
pg.sh -c "create extension if not exists pgcrypto"
pg.sh -c "create extension if not exists pgjwt"
pg.sh -c "create extension if not exists mongo_fdw"

/subconf.sh /tmp/mail/conf.sh
/subconf.sh /tmp/web/conf.sh

# This corresponds to the Dockerfile's:
# ONBUILD COPY conf /tmp/conf
find /tmp/conf -name "conf.sh" -exec /subconf.sh {} \;

# see last.sh
# shellcheck disable=SC1091
source /last

# enable the safeupdate extension
# https://github.com/eradman/pg-safeupdate
# http://postgrest.org/en/v7.0.0/admin.html?highlight=safeupdate#block-full-table-operations
pg.sh -c "alter database ${POSTGRES_DB} set session_preload_libraries = 'safeupdate'"

pg.sh -c "alter database ${POSTGRES_DB} set app.ddl_done to true"
