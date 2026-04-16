#!/bin/bash

pushd schema/"$(basename "$0" .sh)" &&
    pg.sh --set ON_ERROR_STOP=on -1 \
        -f cache_path.sql &&
    popd || exit
