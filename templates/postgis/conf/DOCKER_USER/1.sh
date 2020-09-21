#!/bin/bash
set -e

pushd schema/1

pg.sh -c "comment on schema $SCHEMA is
        \$\$$SCHEMA: Data on things\$\$"

pg.sh -c "set search_path to $SCHEMA, public" \
    -f things.sql

# PostgREST stuff
pushd web
./web.sh
popd

if [ "$DOCKER_ENV" != PRODUCTION ]; then
    pg.sh -c "set search_path to $SCHEMA, public" \
        -f testdata.sql
fi

popd
