#!/bin/bash
set -e

pushd schema/1

    pg.sh -f tbl_thing.sql

    pushd web
        ./web.sh
    popd

    if [ ${DOCKER_ENV} != PRODUCTION ]
    then
        pg.sh -c "set search_path to ${SCHEMA}, public" -f testdata.sql
    fi

popd
