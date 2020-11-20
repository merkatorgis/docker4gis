#!/bin/bash

while ! update-postgis.sh; do
    sleep 1
done

pg.sh -c "alter database ${POSTGRES_DB} set app.ddl_done to false"

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

pg.sh -c "alter database ${POSTGRES_DB} set app.ddl_done to true"
