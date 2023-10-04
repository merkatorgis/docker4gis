#!/bin/bash

pushd schema/"$(basename "$0" .sh)"

pg.sh -f send.sql

popd
