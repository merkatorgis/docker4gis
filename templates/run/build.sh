#!/bin/bash
set -e

POSTGIS_TAG="${POSTGIS_TAG:-latest}"
API_TAG="${API_TAG:-latest}"
GEOSERVER_TAG="${GEOSERVER_TAG:-latest}"
MAPFISH_TAG="${MAPFISH_TAG:-latest}"
POSTFIX_TAG="${POSTFIX_TAG:-latest}"
CRON_TAG="${CRON_TAG:-latest}"
APP_TAG="${APP_TAG:-latest}"
RESOURCES_TAG="${RESOURCES_TAG:-latest}"
PROXY_TAG="${PROXY_TAG:-latest}"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER}"
DOCKER_REPO="${DOCKER_REPO:-run}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
CONTAINER="${RUN_CONTAINER:-$DOCKER_USER-run}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

here=$(dirname "$0")
mkdir -p "${here}/conf/scripts"

main="${here}/conf/${DOCKER_USER}.sh"
echo '#!/bin/bash' > "${main}"
echo "export DOCKER_USER=${DOCKER_USER}" >> "${main}"
chmod +x "${main}"

cp "${DOCKER_BASE}/start.sh"   "${here}/conf/scripts"
cp "${DOCKER_BASE}/network.sh" "${here}/conf/scripts"

component()
{
	envs="${envs}"
	base="${1}"
	impl="${2}"
	tag="${3}"
	shift 3
	src="${DOCKER_BASE}/${base}/run.sh"
	if [ -f "${src}" -a -d "${here}/../${impl}" ]; then
		dst="${here}/conf/scripts/${impl}"
		mkdir -p "${dst}"; cp "${src}" "${dst}"
		echo "${envs} DOCKER_TAG=${tag} __run/scripts/${impl}/run.sh $@" >> "${main}"
	fi
}

component postgis postgis "${POSTGIS_TAG}" postgres pwd dbname
component glassfish api "${API_TAG}" 9090 5858
component geoserver geoserver "${GEOSERVER_TAG}"
component mapfish mapfish "${MAPFISH_TAG}"
component postfix postfix "${POSTFIX_TAG}"
component cron cron "${CRON_TAG}"
component serve app "${APP_TAG}"
envs="APP_CONTAINER=${DOCKER_USER}-res DOCKER_REPO=resources" component serve resources "${RESOURCES_TAG}"
component proxy proxy "${PROXY_TAG}" # 'extra1=http://container1' 'extra2=https://somewhere.outside.com'

docker build -t $IMAGE .

rm -rf "${here}/conf/"
