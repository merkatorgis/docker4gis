#!/bin/bash
set -e

PROXY_HOST=${PROXY_HOST:-localhost}
PROXY_PORT=${PROXY_PORT:-443}
PROXY_PORT_HTTP=${PROXY_PORT_HTTP:-80}
AUTOCERT=${AUTOCERT:-false}

[ -z "$API" ] ||
	echo "API=$API" >>"$ENV_FILE"
[ -z "$APP" ] ||
	echo "APP=$APP" >>"$ENV_FILE"
[ -z "$HOMEDEST" ] ||
	echo "HOMEDEST=$HOMEDEST" >>"$ENV_FILE"
[ -z "$AUTH_PATH" ] ||
	echo "AUTH_PATH=$AUTH_PATH" >>"$ENV_FILE"
[ -z "$CACHE_PATH" ] ||
	echo "CACHE_PATH=$CACHE_PATH" >>"$ENV_FILE"

mkdir -p "$DOCKER_BINDS_DIR"/certificates

PROXY_PORT=$(docker4gis/port.sh "$PROXY_PORT")
PROXY_PORT_HTTP=$(docker4gis/port.sh "$PROXY_PORT_HTTP")

docker container run --restart "$RESTART" --name "$DOCKER_CONTAINER" \
	--env-file "$ENV_FILE" \
	--network "$DOCKER_NETWORK" \
	--add-host host.docker.internal=host-gateway \
	--mount source="$DOCKER_VOLUME",target=/config \
	--env PROXY_HOST="$PROXY_HOST" \
	--env PROXY_PORT="$PROXY_PORT" \
	--env AUTOCERT="$AUTOCERT" \
	--mount type=bind,source="$DOCKER_BINDS_DIR"/certificates,target=/certificates \
	--publish "$PROXY_PORT":443 \
	--publish "$PROXY_PORT_HTTP":80 \
	--detach "$DOCKER_IMAGE" proxy "$@"

# Loop over the config files in the proxy volume, and connect the proxy
# container to any docker network of that name, so that the one proxy container
# can reach different applications' components' containers.
for network in $(docker container exec "$DOCKER_CONTAINER" ls /config); do
	if docker network inspect "$network" >/dev/null 2>&1; then
		docker network connect "$network" "$DOCKER_CONTAINER"
	fi
done
