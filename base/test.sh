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

    # We use the bats that gets installed with npm as a dependency of
    # [bats-helpers](https://www.npmjs.com/package/@drevops/bats-helpers).
    bats=node_modules/.bin/bats

    # Maybe bats-helpers is in package.json, but the user didn't think of runing
    # npm install.
    npm install >/dev/null

    if ! [ -x "$bats" ]; then
        # Install bats along with bats-helpers, if not already installed.
        npm install -D bats-helpers@npm:@drevops/bats-helpers || exit 1
    fi

    # Install our own bats utilities.
    "$DOCKER_BASE"/.plugins/bats/install.sh

    # Run all bats tests.
    time "$bats" --recursive "$dir"
fi
