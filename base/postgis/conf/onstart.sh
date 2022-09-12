#!/bin/bash

# run.sh waits until this is true
pg.sh -c "alter database $POSTGRES_DB set app.ddl_done to false"

extension() {
    pg.sh -c "create extension if not exists $1"
}

# POSTGIS_MAJOR is eg. 2.5 or 3.1
postgis_major_major=$(echo "$POSTGIS_MAJOR" | cut -d'.' -f1)
# from PostGIS 3, postgis_raster is a separate extension
[ "$postgis_major_major" -ge 3 ] && extension postgis_raster

# if the database is unprovisioned, and there is a dump file: restore it; see
# dump_restore
restore

# run the DDL to either provision the database from scratch, or migrate the
# existing database to the latest version
time {
    # maybe this image contains a newer (minor, updatable without dump &
    # restore) version of PostGIS than the last image that served this database
    update-postgis.sh

    extension ogr_fdw
    extension odbc_fdw
    extension plsh
    extension pgcrypto
    extension pgjwt
    extension mongo_fdw
    [ "$POSTGRESQL_VERSION" -lt 14 ] && extension range_agg
    [ "$DOCKER_ENV" = DEVELOPMENT ] || [ "$DOCKER_ENV" = DEV ] && extension pldbgapi

    # clear the "last" file (see last.sh)
    echo '' >/last

    /subconf.sh /tmp/mail/conf.sh
    /subconf.sh /tmp/web/conf.sh

    # This corresponds to the Dockerfile's ONBUILD COPY conf /tmp/conf
    find /tmp/conf -name "conf.sh" -exec /subconf.sh {} \;

    # see last.sh
    # shellcheck disable=SC1091
    source /last
}

# https://github.com/eradman/pg-safeupdate
# http://postgrest.org/en/v7.0.0/admin.html?highlight=safeupdate#block-full-table-operations
# to prevent issues with restoring a dump file, this is deliberately _not_
# loaded in shared_preload_libraries
pg.sh -c "alter database $POSTGRES_DB set session_preload_libraries = 'safeupdate'"

# run.sh waits until this is true
pg.sh -c "alter database $POSTGRES_DB set app.ddl_done to true"
