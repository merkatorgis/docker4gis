#!/bin/bash

IMAGE="$1"
CONTAINER="$2"
FORCE="$3"

TIMESTAMP="$(date +%Y%m%d%H%M%S)"

set +e
if DOCKER_PS=$(sudo docker ps -a | grep "\ ${CONTAINER}$"); then
	OLD_IMAGE=$(echo "$DOCKER_PS" | sed -n -e 's|\w*\s*\(\S*\).*|\1|p')
	if [ "$OLD_IMAGE" = "$IMAGE" -a "$FORCE" != 'force' ]; then
		sudo docker start "$CONTAINER" 2>/dev/null
		exit 1
	else
		sudo docker stop "$CONTAINER" 2>/dev/null
		sudo docker rename "$CONTAINER" "$CONTAINER-$TIMESTAMP"
		sudo docker image tag "$OLD_IMAGE" "$OLD_IMAGE-$TIMESTAMP"
	fi
elif [ "$FORCE" = 'force' ]; then
	sudo docker image tag "$IMAGE" "$IMAGE-$TIMESTAMP" 2>/dev/null
fi
set -e
