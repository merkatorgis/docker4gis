#!/bin/bash

DOCKER_REPO=${1:?Missing first argument: DOCKER_REPO}
tag=${2:?Missing second argument: tag}
shift 2

export DOCKER_REPO

DOCKER_REGISTRY=${DOCKER_REGISTRY:?Missing DOCKER_REGISTRY}
DOCKER_USER=${DOCKER_USER:?Missing DOCKER_USER}

DOCKER_BINDS_DIR=${DOCKER_BINDS_DIR:-~/docker-binds}
mkdir -p "$DOCKER_BINDS_DIR"
DOCKER_BINDS_DIR=$(realpath "$DOCKER_BINDS_DIR")
export DOCKER_BINDS_DIR

export DOCKER_ENV=${DOCKER_ENV:-DEVELOPMENT}

[ "$DOCKER_ENV" = DEVELOPMENT ] &&
    RESTART=no ||
    RESTART=always
export RESTART

DOCKER_IMAGE=$DOCKER_REGISTRY/$DOCKER_USER/$DOCKER_REPO:$tag
export DOCKER_IMAGE

DOCKER_CONTAINER=$DOCKER_USER-$DOCKER_REPO
[ "$DOCKER_REPO" = proxy ] && DOCKER_CONTAINER='docker4gis-proxy'
export DOCKER_CONTAINER

DOCKER_NETWORK=$DOCKER_USER
[ "$DOCKER_REPO" = proxy ] && DOCKER_NETWORK=$DOCKER_CONTAINER
export DOCKER_NETWORK

echo "Starting $DOCKER_CONTAINER from $DOCKER_IMAGE..."

# Pull the image from the registry if we don't have it locally, so that we
# have it ready to run a new container right after we stop the running one.
container=$(docker container create "$DOCKER_IMAGE") || exit 1
docker container rm "$container" >/dev/null

if old_image=$(docker container inspect --format='{{ .Config.Image }}' "$DOCKER_CONTAINER" 2>/dev/null); then
    if [ "$old_image" = "$DOCKER_IMAGE" ]; then
        docker container start "$DOCKER_CONTAINER" &&
            exit 0 || # Existing container from same image is started, and we're done.
            echo "The existing container failed to start; we'll remove it, and create a new one..."
    fi
    docker container stop "$DOCKER_CONTAINER" >/dev/null || exit $?
    docker container rm "$DOCKER_CONTAINER" >/dev/null || exit $?
fi

ENV_FILE=$(mktemp)
finish() {
    err_code=${1:-$?}
    rm "$ENV_FILE"
    exit "$err_code"
}

echo "DOCKER_ENV=$DOCKER_ENV
DOCKER_TAG=$tag
DOCKER_IMAGE=$DOCKER_IMAGE
DOCKER_CONTAINER=$DOCKER_CONTAINER
DOCKER_NETWORK=$DOCKER_NETWORK
DOCKER_VOLUME=$DOCKER_VOLUME
DEBUG=$DEBUG" >>"$ENV_FILE"
export ENV_FILE

# Write environment variables having the "${DOCKER_USER}_${DOCKER_REPO}_" prefix
# (case insensitive) to the "$ENV_FILE" (without the prefix). E.g. a variable
# named MYAPP_MYCOMPONENT_VAR will be an environment variable named VAR in the
# "myapp-mycomponent" container.

# Loop over all environment variables.
for var in $(compgen -e); do
    prefix=${DOCKER_USER}_${DOCKER_REPO}_
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
        # Also export the variable, to make it available in ./run.sh itself.
        export "$name"="${!var}"
    fi
done

export FILEPORT=${FILEPORT:-$DOCKER_BINDS_DIR/fileport/$DOCKER_USER/$DOCKER_REPO}
export RUNNER=${RUNNER:-$DOCKER_BINDS_DIR/runner/$DOCKER_USER/$DOCKER_REPO}

docker4gis=docker4gis
[ -d "$docker4gis" ] || docker4gis="$DOCKER_BASE"/.docker4gis/docker4gis

"$docker4gis"/network.sh "$DOCKER_NETWORK" || finish 2

export DOCKER_VOLUME=$DOCKER_CONTAINER
docker volume create "$DOCKER_VOLUME" >/dev/null || finish 5

# Execute the (base) image's run script, passing args read from its args file,
# substituting environment variables, and skipping lines starting with a #.
if [ -f args ]; then
    envsubst <args | grep -v "^#" | xargs \
        ./run.sh "$@"
else
    ./run.sh "$@"
fi

finish "$?"
