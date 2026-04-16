#!/bin/bash

git fetch
if git status --short --branch | grep behind; then
    echo "Error: git branch is behind; please sync" >&2
    exit 1
fi
if [ "$(git status --short)" ]; then
    echo "Error: git repo has pending changes" >&2
    exit 1
fi
