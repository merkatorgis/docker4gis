#!/bin/bash

if ! command -v bats; then
    bats_url=https://github.com/bats-core/bats-core
    echo "WARN - Cannot test without [bats]($bats_url); continuing without running any tests now."
    echo "Consider npm install -g bats"
    exit
fi

"$DOCKER_BASE"/plugins/validate/install.sh

time bats -r "${1:-.}"
