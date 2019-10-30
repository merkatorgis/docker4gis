#!/bin/bash

pushd schema/1

pg.sh -f tbl_something.sql

popd
