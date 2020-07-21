#!/bin/bash

if ! command -v bats >/dev/null && command -v npm >/dev/null; then
    echo "bats command not found, trying to install it through npm now:"
    npm install -g bats
fi

cp "$(dirname "$0")"/.bats.bash ~
