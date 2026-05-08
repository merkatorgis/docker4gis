load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

function setup() {
    WORKDIR=$(mktemp -d)
}

function teardown() {
    rm -rf "$WORKDIR"
}

@test "'bump' fails outside a docker4gis directory" {
    cd "$WORKDIR"
    run "$DG" bump
    assert_failure
    assert_output --partial "not recognised as a docker4gis"
}

@test "'bump' appends DOCKER4GIS_VERSION to .env" {
    _make_fake_component
    cd "$WORKDIR"
    run "$DG" bump
    assert_success
    assert_file_contains "$WORKDIR/.env" "DOCKER4GIS_VERSION="
}

@test "'bump' echoes the new version" {
    _make_fake_component
    cd "$WORKDIR"
    run "$DG" bump
    assert_success
    assert_output --regexp '^(development|[0-9]+\.[0-9]+\.[0-9]+.*)$'
}

@test "'bump' appends a line rather than replacing the existing DOCKER4GIS_VERSION" {
    _make_fake_component
    cd "$WORKDIR"
    run "$DG" bump
    assert_success
    run grep -c "^DOCKER4GIS_VERSION=" "$WORKDIR/.env"
    assert [ "$output" -ge 2 ]
}

@test "'bump' help shows usage information" {
    run "$DG" bump help
    assert_success
    assert_output --partial "bump"
}
