#!/bin/bash

if ! command -v bats >/dev/null && command -v npm >/dev/null; then
    echo "bats command not found, trying 'sudo npm install -g bats' now:"
    sudo npm install -g bats
fi

cp "$(dirname "$0")"/.bats.bash ~
