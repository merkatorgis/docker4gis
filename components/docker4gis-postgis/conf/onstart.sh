#!/bin/bash

# https://docs.postgrest.org/en/v14/explanations/db_authz.html#functions: By
# default, when a function is created, the privilege to execute it is not
# restricted by role. The function access is PUBLIC — executable by all roles
# (more details at PostgreSQL Privileges page). To disable this behavior, you
# can run the following SQL statement:
pg.sh -c "ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC"

extension() {
    pg.sh -c "create extension if not exists $1"
}

# POSTGIS_MAJOR is eg. 2.5 or 3.1
postgis_major_major=$(echo "$POSTGIS_MAJOR" | cut -d'.' -f1)
# from PostGIS 3, postgis_raster is a separate extension
[ "$postgis_major_major" -ge 3 ] && extension postgis_raster

# If a schema named $DOCKER_USER already exists, restore doesn't do anything.

# First try if a database dump was left in the usual dump location.
restore

# Maybe the image contains a "snaphot" dump to provide an initial setup.
restore snapshot

# run the DDL to either provision the database from scratch, or migrate the
# existing database to the latest version
time {
    # Maybe this image contains a newer (minor, updatable without dump &
    # restore) version of PostGIS than the last image that served this database.
    # See
    # https://github.com/postgis/docker-postgis/blob/master/update-postgis.sh
    update-postgis.sh

    extension ogr_fdw
    [ "$POSTGRESQL_VERSION" -lt 17 ] && extension odbc_fdw
    extension plsh
    extension pgcrypto
    extension pgjwt
    extension mongo_fdw
    [ "$POSTGRESQL_VERSION" -lt 14 ] && extension range_agg
    [ "$DOCKER_ENV" = DEVELOPMENT ] || [ "$DOCKER_ENV" = DEV ] && extension pldbgapi

    echo
    echo "Available ODBC drivers:"
    odbcinst -q -d
}

# https://github.com/eradman/pg-safeupdate
# http://postgrest.org/en/v7.0.0/admin.html?highlight=safeupdate#block-full-table-operations
# to prevent issues with restoring a dump file, this is deliberately _not_
# loaded in shared_preload_libraries
pg.sh -c "alter database $PGDATABASE set session_preload_libraries = 'safeupdate'"

# Signal that the database is ready for use.
pg.sh -c "alter database $PGDATABASE set db.ready to true"
