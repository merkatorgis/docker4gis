#!/bin/bash
set -e

src_dir="${1}"
flush="${2}"
war="${2}"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-docker4gis}"
DOCKER_REPO="${DOCKER_REPO:-api}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
API_CONTAINER="${API_CONTAINER:-$DOCKER_USER-api}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

if [ "${war}" != 'war' ]; then
    echo; echo "Compiling from '${src_dir}'..."

    docker volume create mvndata

    cache_dir=/root/.m2
    if [ "${flush}" == 'flush' ]; then
        cache_dir="${cache_dir}.not"
    fi

    docker container run --rm \
        -v "${src_dir}":/src \
        --mount source=mvndata,target="${cache_dir}" \
        dirichlet/netbeans \
        bash -c '\
            cd /src; \
            mvn \
                -Dmaven.ext.class.path=/usr/local/netbeans/java/maven-nblib/netbeans-eventspy.jar \
                -Dfile.encoding=UTF-8 \
                clean \
                install \
            ; \
        '
fi

echo; echo "Building server from binaries..."
if docker container rm -f "${API_CONTAINER}" 2>/dev/null; then true; fi

read -r -a artifact_id <<< $(grep -oPm1 '(?<=<artifactId>)[^<]+' "${src_dir}/pom.xml")
read -r -a version <<< $(grep -oPm1 '(?<=<version>)[^<]+' "${src_dir}/pom.xml")
build_dir="${src_dir}/target/${artifact_id}-${version}"

HERE=$(dirname "$0")

# Asserting a ./Dockerfile like:
# FROM amazon/aws-eb-glassfish:5.0-al-onbuild-2.11.1
# RUN cp \
#     ./WEB-INF/lib/mysql-*.jar \
#     ${GLASSFISH_HOME}/glassfish/domains/domain1/lib
# RUN mv /var/app/conf/... ...
# RUN /var/app/conf/plugins/.../install.sh
mkdir -p conf
cp -r conf Dockerfile "${HERE}/conf/admin.sh" "${build_dir}"
pushd "${build_dir}"
cp -r "${HERE}/../plugins" "conf"
docker image build -t "${IMAGE}" .
rm -rf conf Dockerfile admin.sh
popd
docker container run -d --name tmp-glassfish-conf "${IMAGE}"
sleep 15
docker container exec tmp-glassfish-conf /var/app/admin.sh
docker container commit tmp-glassfish-conf "${IMAGE}"
docker container rm -f tmp-glassfish-conf
