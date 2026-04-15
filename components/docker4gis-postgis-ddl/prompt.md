This docker4gis-postgis image features a Postgres database. Users are supposed
to extend a custom new image FROM it, "inheriting" this "abstact" image's
features and tools; the extension image's setup looks like the what's in the
`template` directory. We have an encompassing tool ("docker4gis", it's in the
`npm-package` directory; mainly the `docker4gis` executable shell script; it has
a "usage" section listing the available commands, and a "help" system that lists
instructions for each command) that works with these "docker4gis" images; the
tool will call the build.sh script to build the extension image, as well as the
run.sh script to start the container.

It serves 1 database.

It supports multiple schemas.

The schemas to create, and the objects to create in it, are managed through DDL
commands (data defenition language).

Included is a mechanism, `schema.sh`, for managing "migrations" per schema:
- Each schema is in an explict "version";
   - Being the integer value returned by the $schema.__version() function.
- On container start, once the database is ready, the `conf.sh` is called (see
  the `template` dir), which contains a call to `schema.sh` for each schema;
- Schema.sh will lookup the current version in the database, then look in the
  file system if there's an executable `x.sh` where x is 1 higher than the
  current version, and if so, run that, and on to the next, if present.

While this mechanism functions quite well, a major drawback is that to propagate
data model changes, the database image itself needs to get updated, resulting in
having to bring down the running container, and replace it with a new one off
the new image, causing a short downtime even for trivial changes.

So I want to "pull out" the shema.sh mechanism, so that it is no longer part of
the image that the database container runs from.

I do want the DDL to be carefully versioned though. I.e. I want the DDL to land
in a separate Docker image. I created a new, separate repo for this
(docker4gis-postgis-ddl), with its own `package.json`, with its own version
number. The database image's `run.sh` should keep starting the database
container from the proper database image version, but the idea is that most of
the time, that will result in keeping the existing database container running
untouched, since the changes are not in the database component, but in the DDL
component.

The new docker4gis-postgis-ddl should also form a base image, where users would
extend a custom image FROM, for which a template directory would be provided
(the docker4gis tool has a standard mechanism to initialise a local directory
from the template inside the base image).

The admin, mail, web, and wms directories, along with the schema.sh and last.sh
whould move from docker4gis-postgis to docker4gis-postgis-ddl.

docker4gis-postgis-ddl should connect to a running docker4gis-postgis
(extension) container, using plain `psql` installed in an ubuntu image (so that
users can easily add other tools they might need).

While "normal" docker4gis components run detached (as a "server"), the
docker4gis-postgis-ddl should run in the foreground, as a "one-off". I guess it
should be marked as standalone (see the docker4gis tool).

But other than "normal standalone" images, we _do_ need to include it in the
list-of-containers-to-start.

Moreover, it has to start _immediately after_ the postgis component. That is:
after postgis is _ready_ (in the existing docker4gis-postgis run.sh there's a
mechanism for that, using a parameter, that is also used in onstart.sh; the
mechanism should change, because it's no longer about "ddl_done" - maybe it can
even be deprecated, since it might be enough if we just try from the subsequent
docker4gis-postgis-ddl container to run what it needs to run on the database
container, and when it (finally) connects, that probably means that the database
was ready). **And** it has to make the following components to _wait_ until the
docker4gis-postgis-ddl container has finished (but that should be easy; just
`docker container run` without the `-d`).

In the list.sh there's a mechanism that makes the postgis component to start
before any other components. We can probably hard-code there that when we see a
postgis component, we should include the docker4gis-postgis-ddl run commands as
well (and provide helpful error messages should it be missing in the user's
project.)
