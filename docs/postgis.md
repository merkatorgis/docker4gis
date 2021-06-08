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

## Dump & Restore

### Online backup

To dump a snapshot of a running database:

`time docker container exec appname-postgis dump`

To restore a database to the state at the time of the start of a dump:

1. Just in case, download/backup the latest dump files:
   1. `${DOCKER_BINDS_DIR}/fileport/${DOCKER_USER}/${dbname}.roles`;
   1. `${DOCKER_BINDS_DIR}/fileport/${DOCKER_USER}/${dbname}.backup`;
1. Remove the "old" database files:
   1. Remove the current container: `docker container rm -f appname-postgis`;
   1. Remove the database volume: `docker volume rm appname-postgis`;
1. Run the app again - a new, empty database will be created, and the dump
   will be restored in it.

Once restored, or when a new dump is created, the (old) dump file names are suffixed
with a date-time string.

### Upgrade

To move an existing database from one major version of PostgreSQL to another (
e.g. from 10 to 11, from 11 to 12, or from 10 to 12), you'll have to dump and
restore the data\*). Same goes for a major PostGIS upgrade (e.g. from 2 to 3).

Using the `upgrade` command instead of `dump` renders the database read-only
before starting the dump, to prevent the loss of any new data during the upgrade
procedure. In achieving the read-only state, all current connections to the
database are (gracefully) terminated.

1. Build the new-version database image;
1. Dump the database for upgrade: `time docker container exec appname-postgis upgrade` - the database is now read-only;
1. Just in case, download/backup the latest dump files (see above);
1. Remove the "old" database files (see above);
1. Run the new app version, with the new-version database image - the dump is
   restored, and the database is writable again.

Though many things might continue to work on the read-only database, and most
clients probably reconnect automatically, do plan to perform the restore asap.
For instance, PostgREST API queries are likely to fail, since they tend to write
transaction parameters.

Note that upgrades are up-only, e.g. restoring a dump of a PostGIS 3.1 database
into a PostGIS 2.5 database will fail.

\*) Though the [pg_upgrade](https://www.postgresql.org/docs/current/pgupgrade.html)
utility features a more direct migration path, without the need for a dump, this won't
work for a PostGIS database. See PostGIS's docs about
"[hard upgrading](https://postgis.net/docs/manual-dev/postgis_administration.html#hard_upgrade)"
for more information.

### EXCLUDE_SCHEMA

The `EXCLUDE_SCHEMA` environment variable defines any schemas that should not be
included in a database dump for backup or upgrade.

#### Backup excluded schema

```
dump_schema -n ${schemaname}
```

#### Restore excluded schema

```
restore_schema -n ${schemaname}
```
