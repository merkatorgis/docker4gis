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
    # See https://www.shellcheck.net/wiki/SC2044 for the loop over `find`.
    while IFS= read -r -d '' test; do
        if ! "$test"; then
            echo "❌ failure: $test"
            sh_tests_failed=true
        fi
    done < <(find "$dir" -name "test.sh" -print0)
fi

if [ "$bats_tests" ]; then

    # Install our own bats utilities.
    "$DOCKER_BASE"/.plugins/bats/install.sh

    # Git clone case.
    node_modules=$DOCKER_BASE/../node_modules
    # Npx case.
    [ -d "$node_modules" ] || node_modules=$DOCKER_BASE/../../../node_modules
    node_modules=$(realpath "$node_modules")

    # Run all bats tests.
    if ! time "$node_modules/.bin/bats" --recursive "$dir"; then
        bats_tests_failed=true
    fi
fi

! [ "$sh_tests_failed" ] && ! [ "$bats_tests_failed" ]
