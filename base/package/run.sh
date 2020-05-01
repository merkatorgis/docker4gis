#!/bin/bash
set -e

docker_tag="${1:-latest}"

export DOCKER_REGISTRY="${DOCKER_REGISTRY}"
export DOCKER_USER="${DOCKER_USER}"
export DOCKER_ENV="${DOCKER_ENV}"
export PROXY_HOST="${PROXY_HOST}"
export AUTOCERT="${AUTOCERT}"

export SECRET="${SECRET}"
export APP="${APP}"
export API="${API}"
export HOMEDEST="${HOMEDEST}"

export POSTFIX_DESTINATION="${POSTFIX_DESTINATION}"
export POSTFIX_DOMAIN="${POSTFIX_DOMAIN}"

export DOCKER_BINDS_DIR="${DOCKER_BINDS_DIR}"
if [ ! "${DOCKER_BINDS_DIR}" ]
then
	pushd ~
		export DOCKER_BINDS_DIR="$(pwd)/docker-binds"
	popd
fi

echo "
$(date)

Running '${DOCKER_USER}' version: ${docker_tag}

With these settings:

DOCKER_ENV=${DOCKER_ENV}

PROXY_HOST=${PROXY_HOST}
AUTOCERT=${AUTOCERT}

DOCKER_BINDS_DIR=${DOCKER_BINDS_DIR}
DOCKER_REGISTRY=${DOCKER_REGISTRY}

SECRET=${SECRET}
APP=${APP}
API=${API}
HOMEDEST=${HOMEDEST}

POSTFIX_DESTINATION=${POSTFIX_DESTINATION}
POSTFIX_DOMAIN=${POSTFIX_DOMAIN}
" | tee -a ${DOCKER_USER}.log

read -n 1 -p 'Press any key to continue...'
container="${DOCKER_USER}-package"
image="${DOCKER_REGISTRY}${DOCKER_USER}/package:${docker_tag}"

echo "
Executing ${image}" | tee -a ${DOCKER_USER}.log

docker container run --name "${container}" -d "${image}"
docker container cp ${container}:/.run .
docker container rm -f ${container}

.run/${DOCKER_USER}.sh | tee -a ${DOCKER_USER}.log

echo "
$(docker container ls)" | tee -a ${DOCKER_USER}.log

rm -rf .run
