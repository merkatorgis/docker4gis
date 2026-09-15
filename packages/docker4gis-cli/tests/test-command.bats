load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

# Tests for the 'test' / 't' command, which runs a component's test.sh and
# *.bats files via base/test.sh. Docker is assumed available (dev + CI); the
# only Docker interaction is main.sh's health check.

function setup() {
    WORKDIR=$(mktemp -d)
}

function teardown() {
    rm -rf "$WORKDIR"
}

@test "'test' runs a passing test.sh and reports success" {
    _make_fake_component
    printf '#!/bin/bash\nexit 0\n' > "$WORKDIR/test.sh"
    chmod +x "$WORKDIR/test.sh"
    cd "$WORKDIR"
    run "$DG" test
    assert_success
    assert_output --partial "✓"
}

@test "'test' fails when a test.sh fails" {
    _make_fake_component
    printf '#!/bin/bash\nexit 1\n' > "$WORKDIR/test.sh"
    chmod +x "$WORKDIR/test.sh"
    cd "$WORKDIR"
    run "$DG" test
    assert_failure
}

@test "'t' is an alias for 'test'" {
    _make_fake_component
    printf '#!/bin/bash\nexit 0\n' > "$WORKDIR/test.sh"
    chmod +x "$WORKDIR/test.sh"
    cd "$WORKDIR"
    run "$DG" t
    assert_success
    assert_output --partial "✓"
}

@test "'test' warns when no tests are found" {
    _make_fake_component
    cd "$WORKDIR"
    run "$DG" test
    assert_success
    assert_output --partial "no unit tests found"
}

@test "'test FILE' fails for a non-existent file" {
    _make_fake_component
    cd "$WORKDIR"
    run "$DG" test does-not-exist.sh
    assert_failure
}

@test "'test FILE' fails for a file that is not .sh or .bats" {
    _make_fake_component
    printf 'not a test\n' > "$WORKDIR/notatest.txt"
    cd "$WORKDIR"
    run "$DG" test notatest.txt
    assert_failure
    assert_output --partial "must be .sh or .bats"
}

@test "'test' help shows usage information" {
    run "$DG" test help
    assert_success
    assert_output --partial "test"
}

@test "'test COMPONENT' tests the named component, not the current one" {
    _make_fake_monorepo "$WORKDIR"
    app_dir=$(_make_fake_monorepo_component "$WORKDIR" app)
    geoserver_dir=$(_make_fake_monorepo_component "$WORKDIR" geoserver)
    printf '#!/bin/bash\nexit 1\n' > "$app_dir/test.sh"
    chmod +x "$app_dir/test.sh"
    cd "$geoserver_dir"
    run "$DG" test app
    assert_failure
    assert_output --partial "unit tests in $app_dir"
}
