#!/bin/bash

dir="$1"
if ! [ "$dir" ]; then
    dir='test'
    mkdir -p "$dir"
fi
if ! [ -d "$dir" ]; then
    echo "ERROR - cannot find directory $dir"
    exit 22
fi

echo "Running any tests in $dir..."

find "$dir" -name "test.sh" -exec {} \;

if find "$dir" -name "*.bats" >/dev/null 2>&1; then
    "$DOCKER_BASE"/plugins/bats/install.sh
    if ! command -v bats; then
        bats_url=https://github.com/bats-core/bats-core
        echo "WARNING - cannot test without [bats]($bats_url); continuing without running any tests now."
        exit
    fi
    time bats -r "$dir"
fi
