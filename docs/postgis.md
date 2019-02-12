# postgis base image

A [PostgreSQL](https://www.postgresql.org/) database with [PostGIS](https://postgis.net/) extensions.

## Getting started

- Copy the [`templates/postgis`](/templates/postgis) directory into your project's `Docker` directory.
- Rename the `Docker/postgis/schema_name` directory to something that suits your case.
- The `conf.sh` script in that directory will be run at container start.
- It calls the `schema.sh` utility, which will run `1.sh` to create version one of your database schema.
- `1.sh` uses the `pg.sh` utility to run the `create schema` statement.
- You can extend `conf.sh` and/or `1.sh` with what you need to be done.

## Utilities

### conf

Since each `conf/subdir/conf.sh` is run at container start, you could create reusable component images, and stack them. E.g. you build a `comp/postgis` image (with a `conf/comp/conf.sh`), and use it in a different project by setting `FROM comp/postgis` in that project's `Dockerfile`.

### pg.sh

`pg.sh` connects to the database to run sql. Use either of the two options:
- `-c` to run a sql command, eg `pg.sh -c "select 1"`
- `-f` to run a sql file, eg `pg.sh -f commands.sql`

## schema.sh

`schema.sh` enables database schema version management: you start with version 1, later on provide scripts that migrate a version-1 database to version 2, and so on. It will run `1.sh`, then `2.sh`, and so on. If a database already is in version 1, it will skip `1.sh`, and only do `2.sh`, etc. An optional `0.sh` is always run.

To keep track of the schema version in the database, the utility creates a `__version()` function in each schema, that returns the current version number.
