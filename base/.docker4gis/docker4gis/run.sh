#!/bin/bash

repo=$1
tag=$2
shift 2

DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER
DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR
DOCKER_ENV=${DOCKER_ENV:-DEVELOPMENT}
export DOCKER_ENV
[ "$DOCKER_ENV" = DEVELOPMENT ] &&
    RESTART=no ||
    RESTART=always
export RESTART

# create before running any container, to have this owned by the user running
# the run script (instead of a container's root user)
mkdir -p "$DOCKER_BINDS_DIR"/fileport/"$DOCKER_USER"

IMAGE=$DOCKER_REGISTRY$DOCKER_USER/$repo:$tag
export IMAGE
[ "$repo" = proxy ] &&
    CONTAINER=docker4gis-proxy ||
    CONTAINER=$DOCKER_USER-$repo
export CONTAINER
echo
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
finish() {
    rm -rf "$temp"
    exit "${1:-$?}"
}

iptables() {
    # Force the container's ip address to the one listed in iptables.

    # Find the container's HostPorts.
    ports=$(
        docker container inspect \
            --format '
                {{range .HostConfig.PortBindings}}
                    {{range .}}
                        {{.HostPort}}
                    {{end}}
                {{end}}
            ' \
            "$CONTAINER"
    )

    # Find the ip listed for these ports in iptables.
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

    # If no ip is known, then we're done.
    [ "$ip" ] || return

    network=$DOCKER_USER

    # Disconnect the container from the network.
    docker network disconnect "$network" "$CONTAINER"

    # Reconnect, specifying the designated ip address.
    docker network connect --ip "$ip" "$network" "$CONTAINER"
}

if
    dotdocker4gis="$(dirname "$0")"/.docker4gis.sh
    BASE=$("$dotdocker4gis" "$temp" "$IMAGE")
then
    pushd "$BASE" >/dev/null || finish 1
    docker4gis/network.sh &&
        # Execute the (base) image's run script,
        # passing args read from its args file,
        # substituting environment variables,
        # and skipping lines starting with a #.
        envsubst <args | grep -v "^#" | xargs \
            ./run.sh "$@"
    result=$?
    [ "$result" = 0 ] && [ "$DOCKER_ENV" != DEVELOPMENT ] && iptables
    popd >/dev/null || finish 1
fi

finish "$result"
