load ~/.bats/helper.bash
load "$BATS_TEST_DIRNAME/test_helper.bash"

function setup() {
    WORKDIR=$(mktemp -d)
    # Mock docker to fail immediately so init doesn't hang waiting for user
    # input in the proxy component's base-image selection loop.
    _setup_mock_docker
}

function teardown() {
    rm -rf "$WORKDIR"
}

@test "'init' fails when no project name is given" {
    cd "$WORKDIR"
    run bash -c "printf '' | '$DG' init"
    assert_failure
    assert_output --partial "Project name not set"
}

@test "'new' is an alias for 'init' (fails without project name)" {
    cd "$WORKDIR"
    run bash -c "printf '' | '$DG' new"
    assert_failure
    assert_output --partial "Project name not set"
}

@test "'init' creates root .env with correct content" {
    cd "$WORKDIR"
    run bash -c "printf 'n\n' | '$DG' init myproject docker.io"
    assert_success
    assert_file_exists "$WORKDIR/myproject/.env"
    assert_file_contains "$WORKDIR/myproject/.env" "DOCKER4GIS_ROOT=true"
    assert_file_contains "$WORKDIR/myproject/.env" "DOCKER_USER=myproject"
    assert_file_contains "$WORKDIR/myproject/.env" "DOCKER_REGISTRY=docker.io"
    assert_file_contains "$WORKDIR/myproject/.env" "DOCKER4GIS_VERSION="
}

@test "'init' creates root package.json" {
    cd "$WORKDIR"
    run bash -c "printf 'n\n' | '$DG' init myproject docker.io"
    assert_success
    assert_file_exists "$WORKDIR/myproject/package.json"
}

@test "'init' creates ^package component directory" {
    cd "$WORKDIR"
    run bash -c "printf 'n\n' | '$DG' init myproject docker.io"
    assert_success
    assert_dir_exists "$WORKDIR/myproject/components/^package"
}

@test "'init' creates ^package/.env with correct content" {
    cd "$WORKDIR"
    run bash -c "printf 'n\n' | '$DG' init myproject docker.io"
    assert_success
    assert_file_exists "$WORKDIR/myproject/components/^package/.env"
    assert_file_contains "$WORKDIR/myproject/components/^package/.env" "DOCKER_REPO=package"
    assert_file_contains "$WORKDIR/myproject/components/^package/.env" "DOCKER4GIS_VERSION="
}

@test "'init' creates ^package/build.sh as executable" {
    cd "$WORKDIR"
    run bash -c "printf 'n\n' | '$DG' init myproject docker.io"
    assert_success
    assert_file_executable "$WORKDIR/myproject/components/^package/build.sh"
    assert_file_contains "$WORKDIR/myproject/components/^package/build.sh" '#!/bin/bash'
}

@test "'init' creates ^package Azure DevOps pipeline files" {
    cd "$WORKDIR"
    run bash -c "printf 'n\n' | '$DG' init myproject docker.io"
    assert_success
    assert_file_exists "$WORKDIR/myproject/components/^package/azure-pipeline-build-validation.yml"
    assert_file_exists "$WORKDIR/myproject/components/^package/azure-pipeline-continuous-integration.yml"
}

@test "'init' adds proxy component to the project" {
    cd "$WORKDIR"
    run bash -c "printf 'n\n' | '$DG' init myproject docker.io"
    assert_success
    assert_dir_exists "$WORKDIR/myproject/components/myproject-proxy"
    assert_file_exists "$WORKDIR/myproject/components/myproject-proxy/.env"
    assert_file_exists "$WORKDIR/myproject/components/myproject-proxy/Dockerfile"
}

@test "'init' defaults DOCKER_REGISTRY to docker.io when not given" {
    cd "$WORKDIR"
    run bash -c "printf 'docker.io\nn\n' | '$DG' init myproject"
    assert_success
    assert_file_contains "$WORKDIR/myproject/.env" "DOCKER_REGISTRY=docker.io"
}

@test "'init' reports success with project name" {
    cd "$WORKDIR"
    run bash -c "printf 'n\n' | '$DG' init myproject docker.io"
    assert_success
    assert_output --partial "myproject initialised"
}

@test "'init' help shows usage information" {
    run "$DG" init help
    assert_success
    assert_output --partial "init"
}
