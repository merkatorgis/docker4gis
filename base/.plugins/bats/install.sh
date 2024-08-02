#!/bin/bash

here=$(dirname "$0")

mkdir -p ~/.bats
cp "$here"/*.bash ~/.bats

[ "$BATS_LIB_PATH" ] && cp -r "$here"/bats-*-* "$BATS_LIB_PATH"
