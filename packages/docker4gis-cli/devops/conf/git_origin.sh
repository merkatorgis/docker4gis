#!/bin/bash

# This command exists to prevent the PAT from being printed to the console.

origin=$AUTHORISED_COLLECTION_URI$SYSTEM_TEAMPROJECT/_git/$REPOSITORY

if [ "$1" = clone ]; then
    git "$@" --depth 1 "$origin"
else
    git "$@" "$origin"
fi
