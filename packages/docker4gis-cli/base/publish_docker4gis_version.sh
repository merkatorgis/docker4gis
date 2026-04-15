#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

AUTH_FAIL_CODE=11

PUBLISH_MODE="${PUBLISH_MODE:-test}"
DOCKER_IMAGE="${DOCKER_IMAGE:-docker4gis/package}"

validate_mode() {
    case "$PUBLISH_MODE" in
    test | release) ;;
    *)
        echo "Invalid PUBLISH_MODE '$PUBLISH_MODE' (expected test|release)." >&2
        return 1
        ;;
    esac
}

publish_with_token() {
    local token="$1"
    local output_file

    output_file="$(mktemp)"
    set +e
    if [[ "$PUBLISH_MODE" == "test" ]]; then
        NPM_TOKEN="$token" npm publish --tag test 2>&1 | tee "$output_file"
    else
        NPM_TOKEN="$token" npm publish 2>&1 | tee "$output_file"
    fi
    local status=${PIPESTATUS[0]}
    set -e

    if [[ $status -eq 0 ]]; then
        rm -f "$output_file"
        return 0
    fi

    if grep -Eiq "(E401|E403|auth|authentication|unauthorized|forbidden)" \
        "$output_file"; then
        rm -f "$output_file"
        return $AUTH_FAIL_CODE
    fi

    rm -f "$output_file"
    return $status
}

bump_version() {
    npm config set git-tag-version false

    if [[ "$PUBLISH_MODE" == "test" ]]; then
        npm version prerelease --preid test
    else
        npm version patch
    fi
}

update_templates_and_git() {
    local version="$1"
    local tag="$version"
    local message

    if [[ "$PUBLISH_MODE" == "test" ]]; then
        tag="${version%%-*}"
    fi

    git add .
    (
        cd base/package
        ../upgrade_templates.sh "$version" "$tag"
    )
    git add .

    message="$version [skip ci]"
    git commit -m "$message"
    git tag -a "$version" -f -m "$message"
}

build_package_image() {
    (
        cd base/package
        export DOCKER_BASE=..
        ./build.sh
    )
}

push_package_image() {
    local version
    local latest
    local tagged

    version="$(node --print "require('./package.json').version")"
    latest="$DOCKER_IMAGE:latest"
    tagged="$DOCKER_IMAGE:v$version"

    docker image tag "$latest" "$tagged"
    docker image push "$tagged"
}

publish_package() {
    local token
    local status

    token="${NPM_TOKEN:-}"
    if [[ -z "$token" ]]; then
        echo "NPM_TOKEN must be provided before publish." >&2
        return 1
    fi

    if publish_with_token "$token"; then
        return 0
    fi

    status=$?
    if [[ $status -ne $AUTH_FAIL_CODE ]]; then
        return $status
    fi

    echo "Provided NPM token is not authorized." >&2
    return $status
}

push_git_refs() {
    if git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
        git push
        git push --tags
    else
        echo "No upstream configured for current branch; skipping git push." >&2
    fi
}

main() {
    local version

    validate_mode

    cd "$REPO_ROOT"

    version="$(bump_version)"
    update_templates_and_git "$version"
    build_package_image
    push_package_image
    publish_package
    push_git_refs
}

main "$@"
