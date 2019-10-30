#!/bin/bash

pg.sh -c "create schema mail"

pushd schema/1

pg.sh -f fn_send.sql

popd
