#!/bin/bash
set -e

pushd schema/"$(basename "$0" .sh)"

pg.sh -f change_password.sql \
    -f pre_request.sql \
    -f save_password.sql

popd
