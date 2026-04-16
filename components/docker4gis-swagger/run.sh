#!/bin/bash
set -e

proxy=$PROXY_HOST
[ "$PROXY_PORT" ] && proxy=$proxy:$PROXY_PORT
API_URL=${API_URL:-https://$proxy/$DOCKER_USER/api}

docker container run --restart "$RESTART" --name "$CONTAINER" \
	--env-file "$ENV_FILE" \
	--env API_URL="$API_URL" \
	--network "$NETWORK" \
	--detach "$IMAGE" swagger "$@"
