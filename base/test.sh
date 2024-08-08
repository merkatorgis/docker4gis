#!/bin/bash

run() {
    dir=$(realpath .)

    sh_tests=$(find "$dir" -name "test.sh")
    bats_tests=$(find "$dir" -name "*.bats")

    test_type='unit'
    [ "$DOCKER_REPO" = package ] && test_type='integration'

    if ! [ "$sh_tests" ] && ! [ "$bats_tests" ]; then
        echo "> WARNING - no $test_type tests found; consider adding some."
        exit 0
    else
        time run_tests
    fi
}

run_tests() {
    header() {
        local file_type=$1
        echo "Running $file_type $test_type tests in $dir..."
    }

    if [ "$sh_tests" ]; then
        header .sh
        sh_tests_total=$(echo "$sh_tests" | wc --lines)
        sh_tests_run=0
        sh_tests_success=0

        # To exit from a test script, and prevent running any further tests, call
        # the exported function abort_tests.
        export DOCKER4GIS_EXIT_CODE_ABORT=130
        abort_tests() {
            exit "$DOCKER4GIS_EXIT_CODE_ABORT"
        }
        export -f abort_tests

        # See https://www.shellcheck.net/wiki/SC2044 for the loop over `find`.
        while IFS= read -r -d '' test; do
            ((sh_tests_run++))
            if "$test"; then
                ((sh_tests_success++))
                echo " ✓ $test"
            elif [ "$?" = "$DOCKER4GIS_EXIT_CODE_ABORT" ]; then
                echo " 💣 $test"
                sh_tests_aborted=true
                break
            else
                echo " ❌ $test"
            fi
        done < <(find "$dir" -name "test.sh" -print0)

        num() {
            local count=$1
            local noun=$2
            [ "$count" -ne 1 ] && local s=s
            echo "$count $noun$s"
        }

        icon=✅
        sh_tests_not_run=$(("$sh_tests_total" - "$sh_tests_run"))
        sh_tests_failure=$(("$sh_tests_total" - "$sh_tests_success"))
        if [ "$sh_tests_failure" -ne 0 ] || [ "$sh_tests_not_run" -ne 0 ]; then
            sh_tests_failed=true
            icon=❌
        fi

        echo -n "$icon $(num "$sh_tests_total" test)"
        echo -n ", $(num "$sh_tests_failure" failure)"
        [ "$sh_tests_not_run" -ne 0 ] && echo -n ", $sh_tests_not_run not run"
        [ "$sh_tests_aborted" ] && echo -n ", testing aborted"
        echo

        [ "$sh_tests_aborted" ] && exit 1
    fi

    if [ "$bats_tests" ]; then
        header .bats

        # Install our own bats utilities.
        "$DOCKER_BASE"/.plugins/bats/install.sh

        # Don't trace bats, since its output is huge.
        if [ "$DOCKER4GIS_TRACE" ]; then
            set +x
            export SHELLOPTS
        fi

        # Run all bats tests.
        if ! "$BATS" --recursive "$dir"; then
            bats_tests_failed=true
        fi

        # Restore trace.
        if [ "$DOCKER4GIS_TRACE" ]; then
            set -x
            export SHELLOPTS
        fi
    fi

    ! [ "$sh_tests_failed" ] && ! [ "$bats_tests_failed" ]
}

run
