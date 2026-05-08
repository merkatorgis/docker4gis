load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

function setup() {
    WORKDIR=$(mktemp -d)
    git -C "$WORKDIR" init --quiet
    git -C "$WORKDIR" config user.email "test@test.com"
    git -C "$WORKDIR" config user.name "Test"
    touch "$WORKDIR/.gitkeep"
    git -C "$WORKDIR" add "$WORKDIR/.gitkeep"
    git -C "$WORKDIR" commit --message "Initial commit" --quiet
}

function teardown() {
    rm -rf "$WORKDIR"
}

@test "'git-push' reports no changes when working tree is clean" {
    cd "$WORKDIR"
    run "$DG" git-push
    assert_success
    assert_output "No changes to commit."
}

@test "'gp' is an alias for 'git-push'" {
    cd "$WORKDIR"
    run "$DG" gp
    assert_success
    assert_output "No changes to commit."
}

@test "'git-push BRANCH' still reports no changes when tree is clean" {
    cd "$WORKDIR"
    run "$DG" git-push my-branch
    assert_success
    assert_output "No changes to commit."
}

@test "'git-push' help shows usage information" {
    run "$DG" git-push help
    assert_success
    assert_output --partial "git-push"
}
