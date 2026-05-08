load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

# Tests for the default/unknown-command path and the help system.

# --- Unknown / no command ---

@test "unknown command prints usage text and exits 0" {
    run "$DG" totally-unknown-command
    assert_success
    assert_output --partial "Usage:"
}

@test "no command prints usage text and exits 0" {
    run "$DG"
    assert_success
    assert_output --partial "Usage:"
}

# --- Help system: 'dg COMMAND help' ---

@test "'help init' shows help text" {
    run "$DG" help init
    assert_success
    assert_output --partial "init"
}

@test "'init help' shows help text" {
    run "$DG" init help
    assert_success
    assert_output --partial "init"
}

@test "'help version' shows help text" {
    run "$DG" help version
    assert_success
    assert_output --partial "version"
}

@test "'help build' shows help text" {
    run "$DG" help build
    assert_success
    assert_output --partial "build"
}

@test "'help run' shows help text" {
    run "$DG" help run
    assert_success
    assert_output --partial "run"
}

@test "'help push' shows help text" {
    run "$DG" help push
    assert_success
    assert_output --partial "push"
}

@test "'help test' shows help text" {
    run "$DG" help test
    assert_success
    assert_output --partial "test"
}

@test "'help component' shows help text" {
    run "$DG" help component
    assert_success
    assert_output --partial "component"
}

@test "'help bump' shows help text" {
    run "$DG" help bump
    assert_success
    assert_output --partial "bump"
}

@test "'help git-push' shows help text" {
    run "$DG" help git-push
    assert_success
    assert_output --partial "git-push"
}

@test "'help standalone' shows help text" {
    run "$DG" help standalone
    assert_success
    assert_output --partial "standalone"
}

@test "'help all' shows help text" {
    run "$DG" help all
    assert_success
    assert_output --partial "all"
}

@test "'help devops' shows help text" {
    run "$DG" help devops
    assert_success
    assert_output --partial "devops"
}

@test "'help run-single' shows help text" {
    run "$DG" help run-single
    assert_success
    assert_output --partial "run-single"
}

@test "'help bats' shows help text" {
    run "$DG" help bats
    assert_success
    assert_output --partial "bats"
}

# --- Trace mode (smoke test) ---

@test "'trace docker4gis' echoes 'docker4gis' and creates a log file" {
    cd "$BATS_TEST_TMPDIR"
    run "$DG" trace docker4gis
    assert_success
    assert_output --partial "docker4gis"
    assert_file_exists "$BATS_TEST_TMPDIR/docker4gis.log"
}
