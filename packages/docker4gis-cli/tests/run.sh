#!/bin/bash
set -e

PACKAGE_DIR=$(realpath "$(dirname "$0")/..")
export DOCKER_BASE="$PACKAGE_DIR/base"
export DG="$PACKAGE_DIR/docker4gis"

"$DOCKER_BASE/.plugins/bats/install.sh"

[ -d "$PACKAGE_DIR/node_modules" ] || (cd "$PACKAGE_DIR" && npm install)
BATS="$PACKAGE_DIR/node_modules/.bin/bats"

exec "$BATS" --recursive "$PACKAGE_DIR/tests" "$@"
