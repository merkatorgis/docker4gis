load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

# Tests for the 'bats' command, which scaffolds a new .bats test file.

function setup() {
    WORKDIR=$(mktemp -d)
    cd "$WORKDIR"
}

function teardown() {
    rm -rf "$WORKDIR"
}

@test "'bats' creates ./test.bats with helper load by default" {
    run "$DG" bats
    assert_success
    assert_file_exists "$WORKDIR/test.bats"
    assert_file_contains "$WORKDIR/test.bats" "load ~/.bats/helper.bash"
}

@test "'bats' creates ./test.bats with setup_file stub" {
    run "$DG" bats
    assert_success
    assert_file_contains "$WORKDIR/test.bats" "setup_file"
    assert_file_contains "$WORKDIR/test.bats" "helper"
}

@test "'bats FILE' creates a file with the specified name" {
    run "$DG" bats mytest.bats
    assert_success
    assert_file_exists "$WORKDIR/mytest.bats"
    assert_file_contains "$WORKDIR/mytest.bats" "load ~/.bats/helper.bash"
}

@test "'bats' fails if the target file already exists" {
    touch "$WORKDIR/test.bats"
    run "$DG" bats
    assert_failure
    assert_output --partial "already exists"
}

@test "'bats FILE' fails if the named file already exists" {
    touch "$WORKDIR/mytest.bats"
    run "$DG" bats mytest.bats
    assert_failure
    assert_output --partial "already exists"
}

@test "'bats' help shows usage information" {
    run "$DG" bats help
    assert_success
    assert_output --partial "bats"
}
