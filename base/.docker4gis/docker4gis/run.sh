#!/bin/bash

repo=$1
tag=$2
shift 2

DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
export DOCKER_ENV=${DOCKER_ENV:-DEVELOPMENT}
export DOCKER_ENV
[ "$DOCKER_ENV" = DEVELOPMENT ] &&
    RESTART=no ||
    RESTART=always
export RESTART

export FILEPORT=$DOCKER_BINDS_DIR/fileport/$DOCKER_USER/$repo
export RUNNER=$DOCKER_BINDS_DIR/runner/$DOCKER_USER/$repo

IMAGE=$DOCKER_REGISTRY$DOCKER_USER/$repo:$tag
export IMAGE
[ "$repo" = proxy ] &&
    CONTAINER=docker4gis-proxy ||
    CONTAINER=$DOCKER_USER-$repo
export CONTAINER
echo "Starting $CONTAINER from $IMAGE..."

if old_image=$(docker container inspect --format='{{ .Config.Image }}' "$CONTAINER" 2>/dev/null); then
    if [ "$old_image" = "$IMAGE" ]; then
        docker container start "$CONTAINER" &&
            exit 0 || # Existing container from same image is started, and we're done.
            echo "The existing container failed to start; we'll remove it, and create a new one..."
    fi
    docker container stop "$CONTAINER" >/dev/null || exit $?
    docker container rm "$CONTAINER" >/dev/null || exit $?
fi

temp=$(mktemp -d)
ENV_FILE=$(mktemp)
finish() {
    rm -rf "$temp"
    rm "$ENV_FILE"
    exit "${1:-$?}"
}

iptables() {
    # Find the container's ip address in iptables, since it should get that same
    # address agin then. Note that for the proxy container, the address for the
    # "docker4gis" network should be used.

    # Skip all this in Development.
    [ "$DOCKER_ENV" = DEVELOPMENT ] && return

    # Find the container's HostPorts.
    local ports
    ports=$(
        docker container inspect \
            --format '
                {{range .HostConfig.PortBindings}}
                    {{range .}}
                        {{.HostPort}}
                    {{end}}
                {{end}}
            ' \
            "$CONTAINER" \
            2>/dev/null
    )

    # Find any ip listed for these ports in iptables.
    local port
    for port in $ports; do
        which iptables-save >/dev/null 2>&1 &&
            ip=$(sudo iptables-save |
                # Look for lines with this port.
                grep -P "\s+--dport\s+$port" |
                # Only search lines in the NAT table.
                grep MASQUERADE |
                # Pick the address part from patterns like ' -d 172.18.0.13/32'.
                grep -Po "\s+-d\s+\K[^/]+") &&
            # Accept the first match (i.e. prevent overwriting the ip that was
            # found for one port with the empty result for a following
            # non-matched port).
            break
    done

    echo "$ip"
}

echo "DOCKER_USER=$DOCKER_USER
DOCKER_ENV=$DOCKER_ENV
CONTAINER=$CONTAINER" >>"$ENV_FILE"
export ENV_FILE

# Loop over all environment variables.
for var in $(compgen -e); do
    prefix=${DOCKER_USER}_${repo}_
    # Make var and prefix lowercase.
    l_var=${var,,}
    l_prefix=${prefix,,}
    # Test if $l_var starts with $l_prefix.
    if [[ $l_var == ${l_prefix}* ]]; then
        # Find the length of $prefix.
        len=${#prefix}
        # Extract the part of $var that comes after $prefix.
        name=${var:$len}
        # Print name and value to the --env-file file.
        echo "$name=${!var}" >>"$ENV_FILE"
    fi
done

docker4gis/network.sh &&
    IP=$(iptables) &&
    export IP &&
    # Execute the (base) image's run script, passing args read from its args
    # file, substituting environment variables, and skipping lines starting with
    # a #.
    envsubst <args | grep -v "^#" | xargs \
        ./run.sh "$@"

finish "$?"
