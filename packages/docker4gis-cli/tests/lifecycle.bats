load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

# Tests for the container-lifecycle commands 'stop', 'unbuild' and 'geoserver'.
# 'stop' is a safe, side-effect-free operation when no application containers
# are running, so it is exercised end-to-end against real Docker. 'unbuild' and
# 'geoserver' act on images/containers that don't exist in a test, so only their
# argument handling (help) is checked.

function setup() {
    WORKDIR=$(mktemp -d)
}

function teardown() {
    rm -rf "$WORKDIR"
}

@test "'stop' succeeds when no application containers are running" {
    _make_fake_component
    cd "$WORKDIR"
    run "$DG" stop
    assert_success
}

@test "'stop' help shows usage information" {
    run "$DG" stop help
    assert_success
    assert_output --partial "Stop the application"
}

@test "'unbuild' help shows usage information" {
    run "$DG" unbuild help
    assert_success
    assert_output --partial "unbuild"
}

@test "'geoserver' help shows usage information" {
    run "$DG" geoserver help
    assert_success
    assert_output --partial "GeoServer"
}
