#!/bin/bash

dir=$(realpath .)

sh_tests=$(find "$dir" -name "test.sh")
bats_tests=$(find "$dir" -name "*.bats")

if [ "$sh_tests" ] || [ "$bats_tests" ]; then
    echo "Running tests in $dir..."
else
    test_type='unit'
    [ "$DOCKER_REPO" = package ] && test_type='integration'
    echo "> WARNING - no $test_type tests found; consider adding some."
    exit 0
fi

if [ "$sh_tests" ]; then
    time find "$dir" -name "test.sh" -exec {} \;
fi

if [ "$bats_tests" ]; then
    if command -v bats >/dev/null 2>&1; then
        bats='bats'
    else
        bats='npx bats'
    fi
    if "$bats" -v >/dev/null 2>&1; then
        cp "$(dirname "$0")"/.plugins/bats/.bats.bash ~
    else
        bats_url=https://github.com/bats-core/bats-core
        echo "> WARNING - cannot test without [bats]($bats_url); continuing without running any tests now."
        exit 1
    fi
    time "$bats" -r "$dir"
fi
