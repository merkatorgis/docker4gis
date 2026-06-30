load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

# Tests for the 'login' command. We only exercise the argument validation that
# runs before `docker login` is ever called, so no registry network call is
# made.

function setup() {
    WORKDIR=$(mktemp -d)
}

function teardown() {
    rm -rf "$WORKDIR"
}

@test "'login' fails without a password" {
    _make_fake_component
    cd "$WORKDIR"
    run "$DG" login
    assert_failure
    assert_output --partial "password parameter not set"
}

@test "'login' help shows usage information" {
    _make_fake_component
    cd "$WORKDIR"
    run "$DG" login help
    assert_success
    assert_output --partial "login"
}
