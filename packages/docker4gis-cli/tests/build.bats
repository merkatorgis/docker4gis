load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

# Tests for the 'build' / 'b' command. We exercise the build->test gate in
# base/main.sh: a component's unit tests run first, and the build is cancelled
# before any real `docker build` if a test fails. The success path is not
# tested here, to avoid building a real image.

function setup() {
    WORKDIR=$(mktemp -d)
}

function teardown() {
    rm -rf "$WORKDIR"
}

@test "'build' is cancelled when a unit test fails" {
    _make_fake_component
    printf '#!/bin/bash\nexit 1\n' > "$WORKDIR/test.sh"
    chmod +x "$WORKDIR/test.sh"
    cd "$WORKDIR"
    run "$DG" build
    assert_failure
    assert_output --partial "Not starting the build"
}

@test "'b' is an alias for 'build' (also cancelled on a failing test)" {
    _make_fake_component
    printf '#!/bin/bash\nexit 1\n' > "$WORKDIR/test.sh"
    chmod +x "$WORKDIR/test.sh"
    cd "$WORKDIR"
    run "$DG" b
    assert_failure
    assert_output --partial "Not starting the build"
}

@test "'build' help shows usage information" {
    run "$DG" build help
    assert_success
    assert_output --partial "Build a new image"
}
