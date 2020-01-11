#!/bin/bash

pushd schema/1

pg.sh -f send.sql

popd
