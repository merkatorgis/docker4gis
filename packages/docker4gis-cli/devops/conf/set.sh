#!/bin/bash

name=${1:?Name parameter is required}
value=${2:?Value parameter is required}

ENV_FILE=${ENV_FILE:?ENV_FILE value is required}

# Lowercase name.
case ${name,,} in
p | pat)
    name=PAT
    ;;
r | registry | docker_registry)
    name=DOCKER_REGISTRY
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
v | vpn | vpn_pool)
    name=VPN_POOL
    ;;
d | default | default_pool)
    name=DEFAULT_POOL
    ;;
*)
    echo "Unknown name: $name"
    exit 1
    ;;
esac

# Read stored values from file.
# shellcheck source=/dev/null
source "$ENV_FILE"

# Set the new value.
eval "$name='$value'"

# Rewrite all values to file.
echo -n >"$ENV_FILE"
for name in \
    PAT \
    DOCKER_REGISTRY \
    SYSTEM_COLLECTIONURI \
    DEFAULT_POOL \
    VPN_POOL; do
    value=${!name}
    echo "export $name='$value'" >>"$ENV_FILE"
done
