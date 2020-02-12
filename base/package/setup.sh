set -e

push="$1"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER}"
DOCKER_TAG="${DOCKER_TAG:-latest}"

image="${DOCKER_REGISTRY}${DOCKER_USER}/package:${DOCKER_TAG}"

echo; echo "Building ${image}"

here=$(dirname "$0")

run="${here}/conf/.run"
mkdir -p "${run}"

cp "${DOCKER_BASE}/network.sh" "${run}"
cp "${DOCKER_BASE}/port.sh"    "${run}"
cp "${DOCKER_BASE}/start.sh"   "${run}"

main="${run}/${DOCKER_USER}.sh"
echo '#!/bin/bash' > "${main}"
chmod +x "${main}"

echo "export DOCKER_REGISTRY=${DOCKER_REGISTRY}" >> "${main}"
echo "export DOCKER_USER=${DOCKER_USER}" >> "${main}"
echo "export DOCKER_TAG=${DOCKER_TAG}" >> "${main}"
echo ".run/network.sh" >> "${main}"

save()
{
	repo="$1"
	tag="${2:-true}"
	_image="${DOCKER_REGISTRY}${DOCKER_USER}/${repo}"
	if ! docker image inspect "${_image}:latest" 1>/dev/null 2>&1
	then
		# Component whitout an image.
		return
	fi
	if [ "${DOCKER_TAG}" != latest ]
	then
		if "${tag}"
		then
			docker image tag "${_image}:latest" "${_image}:${DOCKER_TAG}"
		fi
		docker image push "${_image}:latest"
		docker image push "${_image}:${DOCKER_TAG}"
	elif [ "${push}" = latest ]
	then
		docker image push "${_image}:latest"
	fi
}

component()
{
	envs="${envs}"
	repo="$1"
	src="$2/run.sh"
	shift 2
	if [ -f "${src}" -a -d "${here}/../${repo}" ]
	then
		cp "${src}" "${run}"
		mv "${run}/run.sh" "${run}/${repo}"
		echo "${envs} .run/${repo} $@" >> "${main}"
		save "${repo}"
	fi
}
