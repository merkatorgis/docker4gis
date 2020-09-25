#!/bin/bash

dir=${1:-test}

if ! [ -d "$dir" ]; then
    if [ "$dir" = "test" ]; then
        echo "WARNING - consider adding some integration tests"
        exit 0
    else
        echo "ERROR - cannot find directory '$dir'"
        exit 22
    fi
fi

echo "Running any tests in $dir..."

find "$dir" -name "test.sh" -exec {} \;

if find "$dir" -name "*.bats" >/dev/null 2>&1; then
    "$DOCKER_BASE"/.plugins/bats/install.sh
    if ! command -v bats >/dev/null 2>&1; then
        bats_url=https://github.com/bats-core/bats-core
        echo "WARNING - cannot test without [bats]($bats_url); continuing without running any tests now."
        exit
    fi
    time bats -r "$dir"
fi
