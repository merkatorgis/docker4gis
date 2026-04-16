#!/bin/bash

# Use pushd to get the version-numbered directory name echoed in the log.
pushd schema/"$(basename "$0" .sh)" &&

    # Create an example table and row security policy.
    pg.sh --set ON_ERROR_STOP=on -1 \
        -c "comment on schema $SCHEMA is \$\$$SCHEMA: Data on things\$\$" \
        -c "set search_path to $SCHEMA, public" \
        -f things.sql &&

    # Prepare for authorised PostgREST access.
    web/web.sh &&

    # Load test data.
    if [ "$DOCKER_ENV" != PRODUCTION ]; then
        pg.sh --set ON_ERROR_STOP=on -1 \
            -c "set search_path to $SCHEMA, public" \
            -f testdata.sql
    fi &&

    # Return.
    popd || exit
