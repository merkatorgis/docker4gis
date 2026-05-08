load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

function setup() {
    WORKDIR=$(mktemp -d)
}

function teardown() {
    rm -rf "$WORKDIR"
}

@test "'docker4gis' action echoes 'docker4gis'" {
    run "$DG" docker4gis
    assert_success
    assert_output "docker4gis"
}

@test "'base' action echoes the DOCKER_BASE directory path" {
    run "$DG" base
    assert_success
    assert_dir_exists "$output"
}

@test "'pwd' action echoes the package directory" {
    expected=$(realpath "$BATS_TEST_DIRNAME/..")
    run "$DG" pwd
    assert_success
    assert_output "$expected"
}

@test "'where' is an alias for 'pwd'" {
    run "$DG" where
    assert_success
    assert_output "$("$DG" pwd)"
}

@test "'version' action echoes a version string" {
    run "$DG" version
    assert_success
    assert_output --regexp '^(development|[0-9]+\.[0-9]+\.[0-9]+.*)$'
}

@test "'version actual' echoes the semver from package.json" {
    run "$DG" version actual
    assert_success
    assert_output --regexp '^[0-9]+\.[0-9]+\.[0-9]+'
}

@test "'v' is an alias for 'version'" {
    run "$DG" v
    assert_success
    assert_output "$("$DG" version)"
}

@test "'version local' echoes DOCKER4GIS_VERSION from .env" {
    echo "DOCKER4GIS_VERSION=1.2.3" > "$WORKDIR/.env"
    echo '{"version":"0.0.0"}' > "$WORKDIR/package.json"
    cd "$WORKDIR"
    run "$DG" version local
    assert_success
    assert_output "1.2.3"
}

@test "'version local' fails outside a docker4gis directory" {
    cd "$WORKDIR"
    run "$DG" version local
    assert_failure
}
