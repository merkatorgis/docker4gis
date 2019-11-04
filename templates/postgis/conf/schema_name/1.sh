#!/bin/bash
set -e

pushd schema/1

    pg.sh -f tbl_something.sql

    pushd web
        ./web.sh
    popd

    if [ ${DOCKER_ENV} != PRODUCTION ]
    then
        pg.sh -f testdata.sql
    fi

popd
