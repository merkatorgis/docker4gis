#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TOKEN_DIR="$CONFIG_HOME/docker4gis/npm-test-publish"
TOKEN_FILE="$TOKEN_DIR/token"
AUTH_FAIL_CODE=11

prompt_for_token() {
    local token

    echo "Provide a granular npm token for test publish." >&2
    echo "Required: package publish for the target package only." >&2
    echo "Recommended: short expiration." >&2

    while true; do
        read -r -s -p "NPM token: " token >&2
        echo >&2
        if [[ -n "$token" ]]; then
            printf '%s' "$token"
            return 0
        fi
        echo "Token cannot be empty." >&2
    done
}

save_token() {
    local token="$1"

    mkdir -p "$TOKEN_DIR"
    (
        umask 177
        printf '%s\n' "$token" >"$TOKEN_FILE"
    )
    chmod 600 "$TOKEN_FILE"
}

load_token() {
    if [[ -f "$TOKEN_FILE" ]]; then
        head -n 1 "$TOKEN_FILE"
    fi
}

resolve_local_token() {
    local token=""
    local token_source=""

    if [[ -n "${NPM_TOKEN:-}" ]]; then
        token="$NPM_TOKEN"
        token_source="env"
    else
        token="$(load_token || true)"
        token_source="cache"
    fi

    if [[ -z "$token" ]]; then
        token="$(prompt_for_token)"
        token_source="prompt"
    fi

    printf '%s\n%s\n' "$token" "$token_source"
}

main() {
    local resolved
    local token
    local token_source
    local status

    resolved="$(resolve_local_token)"
    token="${resolved%%$'\n'*}"
    token_source="${resolved#*$'\n'}"

    if [[ "$token_source" != "env" ]]; then
        save_token "$token"
    fi

    set +e
    NPM_TOKEN="$token" \
        PUBLISH_MODE="${PUBLISH_MODE:-test}" \
        "$REPO_ROOT/base/publish_docker4gis_version.sh" "$@"
    status=$?
    set -e

    if [[ $status -eq 0 ]]; then
        return 0
    fi

    if [[ $status -ne $AUTH_FAIL_CODE ]]; then
        return "$status"
    fi

    if [[ "$token_source" == "env" ]]; then
        echo "Provided NPM_TOKEN is not authorized." >&2
        return "$status"
    fi

    echo "Stored token appears invalid. Please provide a new token." >&2
    token="$(prompt_for_token)"
    save_token "$token"
    NPM_TOKEN="$token" \
        PUBLISH_MODE="${PUBLISH_MODE:-test}" \
        "$REPO_ROOT/base/publish_docker4gis_version.sh" "$@"
}

main "$@"
