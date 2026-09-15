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

@test "'build COMPONENT' builds the named component, not the current one" {
    _make_fake_monorepo "$WORKDIR"
    app_dir=$(_make_fake_monorepo_component "$WORKDIR" app)
    geoserver_dir=$(_make_fake_monorepo_component "$WORKDIR" geoserver)
    printf '#!/bin/bash\nexit 1\n' > "$app_dir/test.sh"
    chmod +x "$app_dir/test.sh"
    cd "$geoserver_dir"
    run "$DG" build app
    assert_failure
    assert_output --partial "unit tests in $app_dir"
    assert_output --partial "Not starting the build"
}

@test "'build' without a component argument builds the current one" {
    _make_fake_monorepo "$WORKDIR"
    _make_fake_monorepo_component "$WORKDIR" app
    geoserver_dir=$(_make_fake_monorepo_component "$WORKDIR" geoserver)
    printf '#!/bin/bash\nexit 1\n' > "$geoserver_dir/test.sh"
    chmod +x "$geoserver_dir/test.sh"
    cd "$geoserver_dir"
    run "$DG" build
    assert_failure
    assert_output --partial "unit tests in $geoserver_dir"
    assert_output --partial "Not starting the build"
}

@test "'build ARG' keeps a non-component argument as a build argument" {
    _make_fake_monorepo "$WORKDIR"
    _make_fake_monorepo_component "$WORKDIR" app
    geoserver_dir=$(_make_fake_monorepo_component "$WORKDIR" geoserver)
    printf '#!/bin/bash\nexit 1\n' > "$geoserver_dir/test.sh"
    chmod +x "$geoserver_dir/test.sh"
    cd "$geoserver_dir"
    run "$DG" build --some-argument
    assert_failure
    assert_output --partial "unit tests in $geoserver_dir"
}
