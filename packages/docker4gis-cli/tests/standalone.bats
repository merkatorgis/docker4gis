load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

function setup() {
    WORKDIR=$(mktemp -d)
}

function teardown() {
    rm -rf "$WORKDIR"
}

@test "'standalone' fails outside a docker4gis directory" {
    cd "$WORKDIR"
    run "$DG" standalone
    assert_failure
    assert_output --partial "not recognised as a docker4gis"
}

@test "'standalone' appends DOCKER4GIS_STANDALONE=true to .env" {
    _make_fake_component
    cd "$WORKDIR"
    run "$DG" standalone
    assert_success
    assert_file_contains "$WORKDIR/.env" "DOCKER4GIS_STANDALONE=true"
}

@test "'standalone' creates run.sh when it does not exist" {
    _make_fake_component
    cd "$WORKDIR"
    run "$DG" standalone
    assert_success
    assert_file_exists "$WORKDIR/run.sh"
    assert_file_executable "$WORKDIR/run.sh"
    assert_file_contains "$WORKDIR/run.sh" '#!/bin/bash'
}

@test "'standalone' does not overwrite an existing run.sh" {
    _make_fake_component
    printf '#!/bin/bash\necho custom\n' > "$WORKDIR/run.sh"
    chmod +x "$WORKDIR/run.sh"
    cd "$WORKDIR"
    run "$DG" standalone
    assert_success
    assert_file_contains "$WORKDIR/run.sh" "echo custom"
}

@test "'standalone' reports the component as standalone" {
    _make_fake_component
    cd "$WORKDIR"
    run "$DG" standalone
    assert_success
    assert_output --partial "standalone"
}

@test "'standalone' fails when given a parameter" {
    _make_fake_component
    cd "$WORKDIR"
    run "$DG" standalone extraarg
    assert_failure
    assert_output --partial "No parameters expected"
}

@test "'standalone' help shows usage information" {
    run "$DG" standalone help
    assert_success
    assert_output --partial "standalone"
}
