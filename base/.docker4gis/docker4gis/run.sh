#!/bin/bash

DOCKER_REPO=$1
tag=$2
shift 2

DOCKER_BINDS_DIR=$DOCKER_BINDS_DIR
DOCKER_REGISTRY=$DOCKER_REGISTRY
DOCKER_USER=$DOCKER_USER

export DOCKER_REPO

export DOCKER_ENV=${DOCKER_ENV:-DEVELOPMENT}

[ "$DOCKER_ENV" = DEVELOPMENT ] &&
    RESTART=no ||
    RESTART=always
export RESTART

IMAGE=$DOCKER_REGISTRY/$DOCKER_USER/$DOCKER_REPO:$tag
export IMAGE

CONTAINER=$DOCKER_USER-$DOCKER_REPO
[ "$DOCKER_REPO" = proxy ] && CONTAINER='docker4gis-proxy'
export CONTAINER

NETWORK=$DOCKER_USER
[ "$DOCKER_REPO" = proxy ] && NETWORK=$CONTAINER
export NETWORK

echo "Starting $CONTAINER from $IMAGE..."

# Pull the image from the registry if we don't have it locally, so that we
# have it ready to run a new container right after we stop the running one.
container=$(docker container create "$IMAGE") || exit 1
docker container rm "$container" >/dev/null

if old_image=$(docker container inspect --format='{{ .Config.Image }}' "$CONTAINER" 2>/dev/null); then
    if [ "$old_image" = "$IMAGE" ]; then
        docker container start "$CONTAINER" &&
            exit 0 || # Existing container from same image is started, and we're done.
            echo "The existing container failed to start; we'll remove it, and create a new one..."
    fi
    docker container stop "$CONTAINER" >/dev/null || exit $?
    docker container rm "$CONTAINER" >/dev/null || exit $?
fi

ENV_FILE=$(mktemp)
finish() {
    err_code=${1:-$?}
    rm "$ENV_FILE"
    exit "$err_code"
}

echo "DOCKER_ENV=$DOCKER_ENV
DOCKER_USER=$DOCKER_USER
DOCKER_REPO=$DOCKER_REPO
CONTAINER=$CONTAINER
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

"$docker4gis"/network.sh "$NETWORK" || finish 2

export VOLUME=$CONTAINER
docker volume create "$VOLUME" >/dev/null || finish 5

# Execute the (base) image's run script, passing args read from its args file,
# substituting environment variables, and skipping lines starting with a #.
if [ -f args ]; then
    envsubst <args | grep -v "^#" | xargs \
        ./run.sh "$@"
else
    ./run.sh "$@"
fi

finish "$?"
