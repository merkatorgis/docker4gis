#!/bin/bash
set -e

PROXY_TAG="${PROXY_TAG:-latest}"
POSTFIX_TAG="${POSTFIX_TAG:-latest}"
POSTGIS_TAG="${POSTGIS_TAG:-latest}"
GEOSERVER_TAG="${GEOSERVER_TAG:-latest}"
MAPFISH_TAG="${MAPFISH_TAG:-latest}"
CRON_TAG="${CRON_TAG:-latest}"
API_TAG="${API_TAG:-latest}"
APP_TAG="${APP_TAG:-latest}"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER}"
DOCKER_REPO="${DOCKER_REPO:-run}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
CONTAINER="${RUN_CONTAINER:-$DOCKER_USER-run}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

here=$(dirname "$0")
"${DOCKER_BASE}/rename.sh" "$IMAGE" "$CONTAINER" force

mkdir -p "${here}/conf/scripts"
pushd "${here}/conf/scripts" > /dev/null
mkdir -p proxy postgis geoserver mapfish postfix cron api app
popd > /dev/null
cp "${DOCKER_BASE}/proxy/run.sh"     "${here}/conf/scripts/proxy"
cp "${DOCKER_BASE}/postgis/run.sh"   "${here}/conf/scripts/postgis"
cp "${DOCKER_BASE}/geoserver/run.sh" "${here}/conf/scripts/geoserver"
cp "${DOCKER_BASE}/mapfish/run.sh"   "${here}/conf/scripts/mapfish"
cp "${DOCKER_BASE}/postfix/run.sh"   "${here}/conf/scripts/postfix"
cp "${DOCKER_BASE}/cron/run.sh"      "${here}/conf/scripts/cron"
cp "${DOCKER_BASE}/glassfish/run.sh" "${here}/conf/scripts/api"
cp "${DOCKER_BASE}/serve/run.sh"     "${here}/conf/scripts/app"
cp "${DOCKER_BASE}/rename.sh"        "${here}/conf/scripts"
cp "${DOCKER_BASE}/network.sh"       "${here}/conf/scripts"

cat << EOF > "${here}/conf/${DOCKER_USER}.sh"
	#!/bin/bash
	PROXY_TAG="${PROXY_TAG}"
	POSTFIX_TAG="${POSTFIX_TAG}"
	POSTGIS_TAG="${POSTGIS_TAG}"
	GEOSERVER_TAG="${GEOSERVER_TAG}"
	MAPFISH_TAG="${MAPFISH_TAG}"
	CRON_TAG="${CRON_TAG}"
	API_TAG="${API_TAG}"
	APP_TAG="${APP_TAG}"

	export DOCKER_USER="${DOCKER_USER}"
EOF
chmod +x "${here}/conf/${DOCKER_USER}.sh"
cat << 'EOF' >> "${here}/conf/${DOCKER_USER}.sh"
	here=$(dirname "$0")

	export DOCKER_REPO='proxy'
	export DOCKER_TAG="$PROXY_TAG"
	"${here}/scripts/proxy/run.sh" # 'extra1=http://container1' 'extra2=https://somewhere.outside.com'

	export DOCKER_REPO='postfix'
	export DOCKER_TAG="$POSTFIX_TAG"
	"${here}/scripts/postfix/run.sh"

	export DOCKER_REPO='postgis'
	export DOCKER_TAG="$POSTGIS_TAG"
	"${here}/scripts/postgis/run.sh" postgres pwd dbname

	export DOCKER_REPO='geoserver'
	export DOCKER_TAG="$GEOSERVER_TAG"
	"${here}/scripts/geoserver/run.sh" -P

	export DOCKER_REPO='mapfish'
	export DOCKER_TAG="$MAPFISH_TAG"
	"${here}/scripts/mapfish/run.sh"

	export DOCKER_REPO='cron'
	export DOCKER_TAG="$CRON_TAG"
	"${here}/scripts/cron/run.sh"

	export DOCKER_REPO='api'
	export DOCKER_TAG="$API_TAG"
	"${here}/scripts/api/run.sh" 9090 5858

	export DOCKER_REPO='app'
	export DOCKER_TAG="$APP_TAG"
	"${here}/scripts/app/run.sh"

	rm -rf "${here}"
EOF

docker build -t $IMAGE .

rm -rf "${here}/conf/scripts" "${here}/conf/${DOCKER_USER}.sh"
