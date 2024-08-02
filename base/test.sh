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

    # Git clone case.
    BATS_LIB_PATH=$DOCKER_BASE/../node_modules
    # Npx case.
    [ -d "$BATS_LIB_PATH" ] || BATS_LIB_PATH=$DOCKER_BASE/../../../node_modules
    BATS_LIB_PATH=$(realpath "$BATS_LIB_PATH")

    export BATS_LIB_PATH

    # Install our own bats utilities.
    "$DOCKER_BASE"/.plugins/bats/install.sh

    # Run all bats tests.
    time "$BATS_LIB_PATH/.bin/bats" --recursive "$dir"
fi
