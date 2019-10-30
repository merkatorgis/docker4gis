#!/bin/bash

pushd schema/1

pg.sh -f fn_send.sql

popd
