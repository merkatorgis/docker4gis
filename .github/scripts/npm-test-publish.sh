#!/usr/bin/env bash
set -euo pipefail

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
    umask 177
    printf '%s\n' "$token" >"$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
}

load_token() {
    if [[ -f "$TOKEN_FILE" ]]; then
        head -n 1 "$TOKEN_FILE"
    fi
}

publish_with_token() {
    local token="$1"
    local output_file

    output_file="$(mktemp)"
    set +e
    NPM_TOKEN="$token" npm publish --tag test 2>&1 | tee "$output_file"
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

main() {
    local token=""
    local token_source=""

    npm version prerelease --preid test --no-git-tag-version

    # Prefer explicit environment token for non-interactive runs.
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

    if publish_with_token "$token"; then
        # Keep cached token owner-only; do not persist env-injected tokens.
        if [[ "$token_source" != "env" ]]; then
            save_token "$token"
        fi
        return 0
    fi

    local status=$?
    if [[ $status -ne $AUTH_FAIL_CODE ]]; then
        return $status
    fi

    echo "Stored token appears invalid. Please provide a new token." >&2
    token="$(prompt_for_token)"
    publish_with_token "$token"
    save_token "$token"
}

main "$@"
