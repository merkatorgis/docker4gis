load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

function setup() {
    WORKDIR=$(mktemp -d)
}

function teardown() {
    rm -rf "$WORKDIR"
}

_add_fake_component() {
    local root="$1"
    local name="$2"
    mkdir -p "$root/components/$name"
    printf 'DOCKER4GIS_VERSION=0.0.1\nDOCKER_REPO=%s\n' "$name" > "$root/components/$name/.env"
    printf '{"version":"0.0.0"}\n' > "$root/components/$name/package.json"
}

@test "'all' fails outside a docker4gis monorepo" {
    cd "$WORKDIR"
    run "$DG" all echo foo
    assert_failure
    assert_output --partial "Could not find monorepo root"
}

@test "'all' runs the command in each recognised component directory" {
    _make_fake_monorepo "$WORKDIR"
    _add_fake_component "$WORKDIR" "comp1"
    _add_fake_component "$WORKDIR" "comp2"
    cd "$WORKDIR"
    run "$DG" all echo hello
    assert_success
    assert_output --partial "hello"
}

@test "'all' visits every component (output contains each component's path)" {
    _make_fake_monorepo "$WORKDIR"
    _add_fake_component "$WORKDIR" "alpha"
    _add_fake_component "$WORKDIR" "beta"
    cd "$WORKDIR"
    run "$DG" all pwd
    assert_success
    assert_output --partial "alpha"
    assert_output --partial "beta"
}

@test "'all' fails when no component has a valid docker4gis .env" {
    _make_fake_monorepo "$WORKDIR"
    mkdir -p "$WORKDIR/components/invalid"
    cd "$WORKDIR"
    run "$DG" all echo foo
    assert_failure
}

@test "'all' help shows usage information" {
    run "$DG" all help
    assert_success
    assert_output --partial "all"
}
