#!/bin/bash

pushd schema/"$(basename "$0" .sh)"

pg.sh -f admin.sql

popd
