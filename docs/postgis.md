# postgis base image

A [PostgreSQL](https://www.postgresql.org/) database with [PostGIS](https://postgis.net/) extensions.

## Getting started

- Copy the [`templates/postgis`](/templates/postgis) directory into your project's `docker` directory.
- Rename the `docker/postgis/schema_name` directory to something that suits your case.
- The `conf.sh` script in that directory will be run at container start.
- It calls the `schema.sh` utility, which will run `1.sh` to create version one of your database schema.
- `1.sh` uses the `pg.sh` utility to run the `create schema` statement.
- You can extend `conf.sh` and/or `1.sh` with what you need to be done.

## Data

The data files are put on a [Docker volume](https://docs.docker.com/storage/volumes/), with the same name as the container running the database. The container can be stopped, or even removed, without losing the data. If you do want to get rid of it, you can remove the volume with `docker volume rm <name>` (to list volume names: `docker volume ls`).

## Utilities

### conf

Since each `conf/subdir/conf.sh` is run at container start, you could create reusable component images, and stack them. E.g. you build a `comp/postgis` image (with a `conf/comp/conf.sh`), and use it in a different project by setting `FROM comp/postgis` in that project's `Dockerfile`.

### pg.sh

`pg.sh` connects to the database to run sql. Use any of the [psql](https://www.postgresql.org/docs/current/app-psql.html) options:
- `-c` to run a sql command, eg `pg.sh -c "select 1"`
- `-f` to run a sql file, eg `pg.sh -f commands.sql`

### schema.sh

`schema.sh` enables database schema version management: you start with version 1, later on provide scripts that migrate a version-1 database to version 2, and so on. It will run `1.sh`, then `2.sh`, and so on. If a database already is in version 1, it will skip `1.sh`, and only do `2.sh`, etc. An optional `0.sh` is always run.

To keep track of the schema version in the database, the utility creates a `__version()` function in each schema, that returns the current version number.

## Upgrade

To move an existing database from one major version of PostgreSQL to another (
e.g. from 10 to 11, from 11 to 12, or from 10 to 12), you'll have to dump and
reload the data:

1. Build the new-version database image.
1. Disconnect all database sessions:
    1. `docker container stop {name}` all containers connected to the database.
    1. Also disconnect all other database users (PGAdmin?)
1. Dump all the data:
    1. `docker container exec -ti appname-postgis bash`
    1. `su postgres`
    1. `pg_dumpall > "/fileport/${POSTGRES_DB}/postgis/db.out"`
    1. `exit`
    1. `exit`
1. Remove the "old" database files:
    1. `docker container rm -f appname-postgis`
    1. `docker volume rm appname-postgis`
1. Run the new app version, with the new-version database image.
1. Modify the container to temporarily disable the "safeupdate" feature:
    1. `docker container exec -ti appname-postgis bash`
    1. `apk add nano`
    1. `nano /etc/postgresql/postgresql.conf`
    1. Comment or delete last line: `shared_preload_libraries=safeupdate`
    1. Ctrl-X, Y to exit nano and save
    1. `exit`
    1. `docker container restart appname-postgis`
1. Again, disconnect all database sessions:
    1. `docker container stop {name}` all containers connected to the database.
    1. Also disconnect all other database users (PGAdmin?)
1. `docker container exec -ti appname-postgis bash`
    1. `su postgres`
    1. Drop any new databases:
        1. `psql -c "drop database ${POSTGRES_DB}" postgres`
        1. `psql -c "alter database template_postgis is_template false" postgres`
        1. `psql -c "drop database template_postgis" postgres`
    1. Load the dump:
        1. `psql -f "/fileport/${POSTGRES_DB}/postgis/db.out" postgres`
    1. `exit`
    1. `exit`
1. Undo any modifications by starting a new container:
    1. `docker container rm -f appname-postgis`
    1. Run the new app version again.
