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
    export FATAL_ERROR=130
    # See https://www.shellcheck.net/wiki/SC2044 for the loop over `find`.
    while IFS= read -r -d '' test; do
        if "$test"; then
            echo "✅ ok  : $test"
        else
            if [ "$?" = "$FATAL_ERROR" ]; then
                echo "💣 fatal : $test"
                exit "$FATAL_ERROR"
            else
                echo "❌ nok : $test"
                sh_tests_failed=true
            fi
        fi
    done < <(find "$dir" -name "test.sh" -print0)
fi

if [ "$bats_tests" ]; then

    # Install our own bats utilities.
    "$DOCKER_BASE"/.plugins/bats/install.sh

    # Find bats.
    bats=$DOCKER_BASE/../../.bin/bats # Npx case.
    if ! [ -x "$bats" ]; then         # Git clone case.
        bats=$DOCKER_BASE/../node_modules/.bin/bats
        [ -x "$bats" ] || (
            # Install docker4gis dependencies, including bats.
            cd "$DOCKER_BASE/.." &&
                npm install
        ) || exit 1
    fi

    # Don't trace bats, since its output is huge.
    if [ "$DOCKER4GIS_TRACE" ]; then
        set +x
        export SHELLOPTS
    fi

    # Run all bats tests.
    if ! time "$bats" --recursive "$dir"; then
        bats_tests_failed=true
    fi

    # Restore trace.
    if [ "$DOCKER4GIS_TRACE" ]; then
        set -x
        export SHELLOPTS
    fi
fi

! [ "$sh_tests_failed" ] && ! [ "$bats_tests_failed" ]
