load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

# Tests for the orchestration commands 'run'/'r', 'br', 'push'/'p',
# 'run-single'/'rs' and 'run-env'/'env'. These perform heavy orchestration or
# real external side-effects (registry push, container startup), so we only
# cover the CLI's own logic that runs before Docker is driven: alias resolution
# and help/usage text. Functional help for 'run', 'push', 'run-single' and
# 'devops' already lives in errors.bats.

function setup() {
    WORKDIR=$(mktemp -d)
}

function teardown() {
    rm -rf "$WORKDIR"
}

@test "'r' is an alias for 'run'" {
    run "$DG" r help
    assert_success
    assert_output --partial "Run the application"
}

@test "'p' is an alias for 'push'" {
    run "$DG" p help
    assert_success
    assert_output --partial "Increment the component's version"
}

@test "'rs' is an alias for 'run-single'" {
    run "$DG" rs help
    assert_success
    assert_output --partial "Run a single container"
}

@test "'br' help shows usage information" {
    run "$DG" br help
    assert_success
    assert_output --partial "First build, then run"
}

@test "'run-env' help shows usage information" {
    _make_fake_component
    cd "$WORKDIR"
    run "$DG" run-env help
    assert_success
    assert_output --partial "environment variables"
}

@test "'env' is an alias for 'run-env'" {
    _make_fake_component
    cd "$WORKDIR"
    run "$DG" env help
    assert_success
    assert_output --partial "environment variables"
}
