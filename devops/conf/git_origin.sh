#!/bin/bash

# This command exists to prevent the PAT from being printed to the console.

origin=$AUTHORISED_COLLECTION_URI$SYSTEM_TEAMPROJECT/_git/$REPOSITORY

git "$@" "$origin"
