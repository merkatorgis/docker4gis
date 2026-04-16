#!/bin/bash
set -e

default_logging_profile=PRODUCTION_LOGGING
[ "$DOCKER_ENV" = DEVELOPMENT ] && default_logging_profile=DEFAULT_LOGGING
GEOSERVER_LOGGING_PROFILE=${GEOSERVER_LOGGING_PROFILE:-$default_logging_profile}

GEOSERVER_PORT=$(docker4gis/port.sh "${GEOSERVER_PORT:-58080}")

docker container run --restart "$RESTART" --name "$DOCKER_CONTAINER" \
	--env-file "$ENV_FILE" \
	--env GEOSERVER_LOGGING_PROFILE="$GEOSERVER_LOGGING_PROFILE" \
	--publish "$GEOSERVER_PORT":8080 \
	--network "$DOCKER_NETWORK" \
	--detach "$DOCKER_IMAGE" geoserver "$@"
