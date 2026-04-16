#!/bin/bash
set -e

mkdir -p "$FILEPORT"

PGRST_JWT_SECRET=$(
	docker container exec "$DOCKER_USER"-postgis pg.sh \
		force \
		-Atc "select current_setting('app.jwt_secret')"
)

proxy=$PROXY_HOST
[ "$PROXY_PORT" ] && proxy=$proxy:$PROXY_PORT
PGRST_OPENAPI_SERVER_PROXY_URI=${PGRST_OPENAPI_SERVER_PROXY_URI:-https://$proxy/$DOCKER_USER/$DOCKER_REPO}

docker container run --restart "$RESTART" --name "$CONTAINER" \
	--env-file "$ENV_FILE" \
	--env PGRST_JWT_SECRET="$PGRST_JWT_SECRET" \
	--env PGRST_OPENAPI_SERVER_PROXY_URI="$PGRST_OPENAPI_SERVER_PROXY_URI" \
	--mount type=bind,source="$FILEPORT",target=/fileport \
	--mount source="$VOLUME",target=/volume \
	--network "$NETWORK" \
	--detach "$IMAGE" postgrest "$@"
