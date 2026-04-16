#!/bin/bash

here=$(dirname "$0")

mkdir -p ~/.bats
cp "$here"/*.bash ~/.bats
