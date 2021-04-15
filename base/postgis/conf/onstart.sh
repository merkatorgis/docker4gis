#!/bin/bash

# run.sh waits until this is true
pg.sh -c "alter database ${POSTGRES_DB} set app.ddl_done to false"

# see dump_restore
time if ! restore; then
    # we didn't restore an existing dump in an unprovisioned database, so we're
    # either provisioning a new database from its own DDL, or updating an
    # existing database with any new DDL

    # maybe this image contains an newer (minor, updatable without dump &
    # restore) version of PostGIS than the last image that served this database
    update-postgis.sh

    extension() {
        pg.sh -c "create extension if not exists $1"
    }

    # POSTGIS_MAJOR is eg. 2.5 or 3.1
    postgis_major_major=$(echo "$POSTGIS_MAJOR" | cut -d'.' -f1)
    # from PostGIS 3, postgis_raster is a separate extension
    [ "$postgis_major_major" -ge 3 ] && extension postgis_raster

    extension ogr_fdw
    extension odbc_fdw
    extension plsh
    extension pgcrypto
    extension pgjwt
    extension mongo_fdw

    # clear the "last" file (see last.sh)
    echo '' >/last

    /subconf.sh /tmp/mail/conf.sh
    /subconf.sh /tmp/web/conf.sh

    # This corresponds to the Dockerfile's ONBUILD COPY conf /tmp/conf
    find /tmp/conf -name "conf.sh" -exec /subconf.sh {} \;

    # see last.sh
    # shellcheck disable=SC1091
    source /last
fi

# enable the safeupdate extension
# https://github.com/eradman/pg-safeupdate
# http://postgrest.org/en/v7.0.0/admin.html?highlight=safeupdate#block-full-table-operations
pg.sh -c "alter database ${POSTGRES_DB} set session_preload_libraries = 'safeupdate'"

# run.sh waits until this is true
pg.sh -c "alter database ${POSTGRES_DB} set app.ddl_done to true"
