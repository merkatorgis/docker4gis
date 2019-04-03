#!/bin/bash
set -e

docker_tag="${1:-latest}"

export DOCKER_USER="${DOCKER_USER}"
export DOCKER_REGISTRY="${DOCKER_REGISTRY}"
export DOCKER_ENV="${DOCKER_ENV}"
export PROXY_HOST="${PROXY_HOST:-localhost}"

export NETWORK_NAME="${DOCKER_USER}-net"
export POSTGIS_PORT="${POSTGIS_PORT:-5432}"
export POSTFIX_PORT="${POSTFIX_PORT:-25}"
export PROXY_PORT="${PROXY_PORT:-443}"
export SECRET='xxx'
export APP="${APP}"
export API="${API}"
export HOMEDEST="/app"

export DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR}"
if [ "${DOCKER_BINDS_DIR}" == '' ]; then
	pushd ~
	export DOCKER_BINDS_DIR="$(pwd)/docker-binds"
	popd
fi

echo "
About to run ${DOCKER_USER} version: ${docker_tag}

With these settings:

DOCKER_ENV=${DOCKER_ENV}

PROXY_HOST=${PROXY_HOST}

DOCKER_BINDS_DIR=${DOCKER_BINDS_DIR}
DOCKER_REGISTRY=${DOCKER_REGISTRY}
NETWORK_NAME=${NETWORK_NAME}
POSTGIS_PORT=${POSTGIS_PORT}
POSTFIX_PORT=${POSTFIX_PORT}
PROXY_PORT=${PROXY_PORT}
APP=${APP}
API=${API}
HOMEDEST=${HOMEDEST}
"
read -n 1 -p 'Press any key to continue...'

container="${DOCKER_USER}-run"
image="${DOCKER_REGISTRY}${DOCKER_USER}/run:${docker_tag}"

echo; echo "Executing ${image}"

docker container run --name "${container}" -d "${image}"
docker container cp ${container}:/tmp/__run .
docker container rm -f ${container}

__run/${DOCKER_USER}.sh

rm -rf __run

echo; docker container ls
