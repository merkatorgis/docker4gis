#!/bin/bash

# https://www.postgresql.org/docs/current/libpq-envars.html
[ "$PGHOSTADDR" ] || export PGHOST=${PGHOST:-$DOCKER_USER-postgis}
export PGPORT=${PGPORT:-5432}
export PGDATABASE=${PGDATABASE:-postgres}
export PGUSER=${PGUSER:-postgres}
export PGPASSWORD=${PGPASSWORD:-postgres}

# Wait until the database is ready.
while ! psql -c "select PostGIS_full_version()" >/dev/null 2>&1; do
	sleep 1
done

force=$1
if [ "$force" = force ]; then
	shift 1
	# force = must succeed.
	while ! psql "$@" 2>/dev/null; do
		sleep 1
	done
else
	psql "$@"
fi
