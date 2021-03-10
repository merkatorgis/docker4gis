#!/bin/bash

DOCKER_BASE=$(realpath "$(dirname "$0")")
DOCKER_APP_DIR=$DOCKER_APP_DIR

dir=$DOCKER_APP_DIR/${1:-test}

if ! [ -d "$dir" ]; then
    if [ "$dir" = "$DOCKER_APP_DIR/test" ]; then
        echo "> WARNING - no integration tests found; consider adding some."
        exit 0
    else
        echo "> ERROR - cannot find directory '$dir'."
        exit 22
    fi
fi

sh_tests=$(find "$dir" -name "test.sh")
bats_tests=$(find "$dir" -name "*.bats")

if [ "$sh_tests" ] || [ "$bats_tests" ]; then
    echo "Running tests in $dir..."
else
    exit 0
fi

time find "$dir" -name "test.sh" -exec {} \;

if [ "$bats_tests" ]; then
    "$DOCKER_BASE"/.plugins/bats/install.sh
    if ! command -v bats >/dev/null 2>&1; then
        bats_url=https://github.com/bats-core/bats-core
        echo "> WARNING - cannot test without [bats]($bats_url); continuing without running any tests now."
        exit
    fi
    time bats -r "$dir"
fi
