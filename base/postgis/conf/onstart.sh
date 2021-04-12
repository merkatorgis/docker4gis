#!/bin/bash

pg.sh -c "alter database ${POSTGRES_DB} set app.ddl_done to false"

dump="/fileport/$DOCKER_USER/$POSTGRES_DB" # cf dump.sh
if ! pg.sh -c "select current_setting('app.configured')" >/dev/null 2>&1 &&
    [ -f "$dump.roles" ] &&
    [ -f "$dump.backup" ]; then
    # restore dump in empty database

    # first restore the roles (which are not included in the backupfile)
    pg.sh -f "$dump.roles"

    # prevent "schema already exists" errors
    pg.sh -c "drop schema if exists tiger_data cascade"
    pg.sh -c "drop schema if exists tiger cascade"
    # restore from the backup file
    perl "$(find / -name postgis_restore.pl 2>/dev/null)" "$dump.backup" |
        psql -U "$POSTGRES_USER" "$POSTGRES_DB" # using pg.sh here would give search path related errors

    # mark the dump files as done
    for f in "$dump.roles" "$dump.backup" "$dump.backup.lst"; do
        mv "$f" "$f.$(date -I'seconds')"
    done

    if ! pg.sh -c "select current_setting('app.jwt_secret')" >/dev/null 2>&1; then
        # fix missing setting; cf web/1.sh
        jwt_secret=$(pg.sh -Atc 'select gen_random_uuid()::text || gen_random_uuid()::text')
        pg.sh -c "alter database $POSTGRES_DB set app.jwt_secret to '$jwt_secret'"
    fi

else
    # start with existing database

    update-postgis.sh

    echo "Next CREATE EXTENSION command will fail for PostGIS < 3."
    echo "It's OK to ignore that error."
    pg.sh -c "create extension if not exists postgis_raster"

    pg.sh -c "create extension if not exists ogr_fdw"
    pg.sh -c "create extension if not exists odbc_fdw"
    pg.sh -c "create extension if not exists plsh"
    pg.sh -c "create extension if not exists pgcrypto"
    pg.sh -c "create extension if not exists pgjwt"
    pg.sh -c "create extension if not exists mongo_fdw"

    # clear the "last" file (see last.sh)
    echo '' >/last

    /subconf.sh /tmp/mail/conf.sh
    /subconf.sh /tmp/web/conf.sh

    # This corresponds to the Dockerfile's:
    # ONBUILD COPY conf /tmp/conf
    find /tmp/conf -name "conf.sh" -exec /subconf.sh {} \;

    # see last.sh
    # shellcheck disable=SC1091
    source /last
fi

# this setting is used in the test above (the value doesn't matter; it just
# needs to be set)
pg.sh -c "alter database $POSTGRES_DB set app.configured to true"

# enable the safeupdate extension
# https://github.com/eradman/pg-safeupdate
# http://postgrest.org/en/v7.0.0/admin.html?highlight=safeupdate#block-full-table-operations
pg.sh -c "alter database ${POSTGRES_DB} set session_preload_libraries = 'safeupdate'"

pg.sh -c "alter database ${POSTGRES_DB} set app.ddl_done to true"
