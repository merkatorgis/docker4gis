load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

function setup() {
    WORKDIR=$(mktemp -d)
    # Mock docker to fail immediately so component selection doesn't hang.
    _setup_mock_docker
}

function teardown() {
    rm -rf "$WORKDIR"
}

# --- component / c ---

@test "'component' fails outside a docker4gis project" {
    cd "$WORKDIR"
    run "$DG" component mycomp
    assert_failure
    assert_output --partial "Not in a docker4gis project"
}

@test "'c' is an alias for 'component' (same error outside project)" {
    cd "$WORKDIR"
    run "$DG" c mycomp
    assert_failure
    assert_output --partial "Not in a docker4gis project"
}

@test "'component' creates component directory inside a monorepo" {
    _make_fake_monorepo "$WORKDIR"
    cd "$WORKDIR"
    run bash -c "printf 'n\n' | '$DG' component mycomp"
    assert_success
    assert_dir_exists "$WORKDIR/components/testapp-mycomp"
}

@test "'component' creates .env in component directory" {
    _make_fake_monorepo "$WORKDIR"
    cd "$WORKDIR"
    run bash -c "printf 'n\n' | '$DG' component mycomp"
    assert_success
    assert_file_exists "$WORKDIR/components/testapp-mycomp/.env"
    assert_file_contains "$WORKDIR/components/testapp-mycomp/.env" "DOCKER4GIS_VERSION="
}

@test "'component' creates Dockerfile in component directory" {
    _make_fake_monorepo "$WORKDIR"
    cd "$WORKDIR"
    run bash -c "printf 'n\n' | '$DG' component mycomp"
    assert_success
    assert_file_exists "$WORKDIR/components/testapp-mycomp/Dockerfile"
}

@test "'component' creates Azure DevOps pipeline files" {
    _make_fake_monorepo "$WORKDIR"
    cd "$WORKDIR"
    run bash -c "printf 'n\n' | '$DG' component mycomp"
    assert_success
    assert_file_exists "$WORKDIR/components/testapp-mycomp/azure-pipeline-build-validation.yml"
    assert_file_exists "$WORKDIR/components/testapp-mycomp/azure-pipeline-continuous-integration.yml"
}

@test "'component' prefixes directory name with DOCKER_USER" {
    _make_fake_monorepo "$WORKDIR"
    cd "$WORKDIR"
    run bash -c "printf 'n\n' | '$DG' component mycomp"
    assert_success
    assert_dir_exists "$WORKDIR/components/testapp-mycomp"
    assert_not_exists "$WORKDIR/components/mycomp"
}

@test "'component' help shows usage information" {
    run "$DG" component help
    assert_success
    assert_output --partial "component"
}

# --- base-component ---

@test "'base-component' fails outside a docker4gis monorepo" {
    cd "$WORKDIR"
    run "$DG" base-component mycomp
    assert_failure
    assert_output --partial "Not in a docker4gis monorepo"
}

@test "'base-component' fails when no name is given" {
    _make_fake_monorepo "$WORKDIR"
    cd "$WORKDIR"
    run bash -c "printf '' | '$DG' base-component"
    assert_failure
    assert_output --partial "Base component name not set"
}

@test "'base-component' creates component directory with docker4gis- prefix" {
    _make_fake_monorepo "$WORKDIR"
    cd "$WORKDIR"
    run "$DG" base-component mycomp
    assert_success
    assert_dir_exists "$WORKDIR/components/docker4gis-mycomp"
}

@test "'base-component' creates .env with docker4gis user and registry" {
    _make_fake_monorepo "$WORKDIR"
    cd "$WORKDIR"
    run "$DG" base-component mycomp
    assert_success
    assert_file_exists "$WORKDIR/components/docker4gis-mycomp/.env"
    assert_file_contains "$WORKDIR/components/docker4gis-mycomp/.env" "DOCKER_USER=docker4gis"
    assert_file_contains "$WORKDIR/components/docker4gis-mycomp/.env" "DOCKER_REGISTRY=docker.io"
}

@test "'base-component' creates Dockerfile from template" {
    _make_fake_monorepo "$WORKDIR"
    cd "$WORKDIR"
    run "$DG" base-component mycomp
    assert_success
    assert_file_exists "$WORKDIR/components/docker4gis-mycomp/Dockerfile"
}

@test "'base-component' creates package.json" {
    _make_fake_monorepo "$WORKDIR"
    cd "$WORKDIR"
    run "$DG" base-component mycomp
    assert_success
    assert_file_exists "$WORKDIR/components/docker4gis-mycomp/package.json"
}

@test "'base-component' creates Azure DevOps pipeline files" {
    _make_fake_monorepo "$WORKDIR"
    cd "$WORKDIR"
    run "$DG" base-component mycomp
    assert_success
    assert_file_exists "$WORKDIR/components/docker4gis-mycomp/azure-pipeline-build-validation.yml"
    assert_file_exists "$WORKDIR/components/docker4gis-mycomp/azure-pipeline-continuous-integration.yml"
}

@test "'base-component' fails if directory already exists" {
    _make_fake_monorepo "$WORKDIR"
    mkdir -p "$WORKDIR/components/docker4gis-mycomp"
    cd "$WORKDIR"
    run "$DG" base-component mycomp
    assert_failure
    assert_output --partial "Directory already exists"
}

@test "'base-component' help shows usage information" {
    run "$DG" base-component help
    assert_success
    assert_output --partial "base component"
}
