#!/bin/bash

name=${1:?Name is required}
value=${2:?Value is required}

env_file=/devops/env_file

# Lowercase name.
case ${name,,} in
r | registry | docker_registry)
    name=DOCKER_REGISTRY
    ;;
t | pat)
    name=PAT
    ;;
o | organisation | organization | system_collectionuri)
    name=SYSTEM_COLLECTIONURI
    # If value doesn't start with https://, prepend it.
    if [[ ! $value =~ ^https:// ]]; then
        # If value contains /, then error.
        if [[ $value =~ / ]]; then
            echo "Invalid value: $value"
            exit 1
        fi
        value=https://dev.azure.com/$value/
    fi
    # If value doesn't end with /, append it.
    if [[ ! $value =~ /$ ]]; then
        value+=/
    fi
    ;;
p | pool | vpn_pool)
    name=VPN_POOL
    ;;
*)
    echo "Unknown name: $name"
    exit 1
    ;;
esac

# Append new value to file.
echo "export $name=$value" >>"$env_file"

# Read current values from file.
# shellcheck source=/dev/null
source "$env_file"

# Rewrite all values to file.
echo -n >"$env_file"
for var in \
    DOCKER_REGISTRY \
    PAT \
    SYSTEM_COLLECTIONURI \
    VPN_POOL; do
    echo "export $var=${!var}" >>"$env_file"
done
