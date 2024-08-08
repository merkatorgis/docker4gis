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
    # To exit from a test script, and prevent running any further tests, call
    # the exported function abort_tests.
    export DOCKER4GIS_EXIT_CODE_ABORT=130
    abort_tests() {
        exit "$DOCKER4GIS_EXIT_CODE_ABORT"
    }
    export -f abort_tests
    # See https://www.shellcheck.net/wiki/SC2044 for the loop over `find`.
    while IFS= read -r -d '' test; do
        if "$test"; then
            echo "✓ $test"
        else
            if [ "$?" = "$DOCKER4GIS_EXIT_CODE_ABORT" ]; then
                echo "💣 $test"
                exit "$DOCKER4GIS_EXIT_CODE_ABORT"
            else
                echo "✕ $test"
                sh_tests_failed=true
            fi
        fi
    done < <(find "$dir" -name "test.sh" -print0)
fi

if [ "$bats_tests" ]; then

    # Install our own bats utilities.
    "$DOCKER_BASE"/.plugins/bats/install.sh

    # Don't trace bats, since its output is huge.
    if [ "$DOCKER4GIS_TRACE" ]; then
        set +x
        export SHELLOPTS
    fi

    # Run all bats tests.
    if ! time "$BATS" --recursive "$dir"; then
        bats_tests_failed=true
    fi

    # Restore trace.
    if [ "$DOCKER4GIS_TRACE" ]; then
        set -x
        export SHELLOPTS
    fi
fi

! [ "$sh_tests_failed" ] && ! [ "$bats_tests_failed" ]
