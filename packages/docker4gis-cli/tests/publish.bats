load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

PUBLISH_SCRIPT="$(realpath "$BATS_TEST_DIRNAME/../base/publish_docker4gis_version.sh")"

function setup() {
    WORKDIR=$(mktemp -d)
    mkdir -p "$WORKDIR/mock-bin"
    NPM_ARGS_FILE="$WORKDIR/npm-args"
    export PATH="$WORKDIR/mock-bin:$PATH"
}

function teardown() {
    rm -rf "$WORKDIR"
}

# Install an npm stub that records its arguments, prints $2, and exits $1.
_mock_npm() {
    local exit_code="$1"
    local message="${2:-}"
    cat >"$WORKDIR/mock-bin/npm" <<EOF
#!/bin/bash
printf '%s\n' "\$*" >>"$NPM_ARGS_FILE"
[ -z '$message' ] || echo '$message' >&2
exit $exit_code
EOF
    chmod +x "$WORKDIR/mock-bin/npm"
}

@test "publish_package fails when npm fails" {
    _mock_npm 1 "npm error code E500"
    # shellcheck disable=SC1090
    run env NPM_TOKEN=token PUBLISH_MODE=release bash -c \
        "source '$PUBLISH_SCRIPT'; publish_package"
    assert_failure
    assert_output --partial "npm publish failed"
}

@test "publish_package reports an unauthorised token" {
    _mock_npm 1 "npm error code E403 Forbidden"
    run env NPM_TOKEN=token PUBLISH_MODE=release bash -c \
        "source '$PUBLISH_SCRIPT'; publish_package"
    assert_failure 11
    assert_output --partial "not authorized"
}

@test "publish_package succeeds when npm succeeds" {
    _mock_npm 0 ""
    run env NPM_TOKEN=token PUBLISH_MODE=release bash -c \
        "source '$PUBLISH_SCRIPT'; publish_package"
    assert_success
}

@test "release mode stages the publish" {
    _mock_npm 0 ""
    run env NPM_TOKEN=token PUBLISH_MODE=release bash -c \
        "source '$PUBLISH_SCRIPT'; publish_package"
    assert_success
    run cat "$NPM_ARGS_FILE"
    assert_output "stage publish"
}

@test "test mode stages the publish with the test tag" {
    _mock_npm 0 ""
    run env NPM_TOKEN=token PUBLISH_MODE=test bash -c \
        "source '$PUBLISH_SCRIPT'; publish_package"
    assert_success
    run cat "$NPM_ARGS_FILE"
    assert_output "stage publish --tag test"
}

@test "publish_package requires a token" {
    _mock_npm 0 ""
    run env -u NPM_TOKEN PUBLISH_MODE=release bash -c \
        "source '$PUBLISH_SCRIPT'; publish_package"
    assert_failure 1
    assert_output --partial "NPM_TOKEN must be provided"
}
