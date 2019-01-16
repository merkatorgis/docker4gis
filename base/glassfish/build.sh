#!/bin/bash
set -e

src_dir="${1}"

DOCKER_REGISTRY="${DOCKER_REGISTRY}"
DOCKER_USER="${DOCKER_USER:-merkatorgis}"
DOCKER_REPO="${DOCKER_REPO:-api}"
DOCKER_TAG="${DOCKER_TAG:-latest}"
API_CONTAINER="${API_CONTAINER:-$DOCKER_USER-api}"

IMAGE="${DOCKER_REGISTRY}${DOCKER_USER}/${DOCKER_REPO}:${DOCKER_TAG}"

echo; echo "Building $IMAGE"

echo; echo "Compiling from '${src_dir}'..."

docker volume create mvndata

docker container run --rm \
    --mount source=mvndata,target=/root/.m2 \
    -v "${src_dir}":/src \
    "${DOCKER_REGISTRY}dirichlet/netbeans" \
    bash -c 'cd /src; mvn -Dmaven.ext.class.path=/usr/local/netbeans/java/maven-nblib/netbeans-eventspy.jar -Dfile.encoding=UTF-8 install'

echo; echo "Building server from binaries..."

read -r -a artifact_id <<< $(grep -oPm1 '(?<=<artifactId>)[^<]+' "${src_dir}/pom.xml")
read -r -a version <<< $(grep -oPm1 '(?<=<version>)[^<]+' "${src_dir}/pom.xml")
build_dir="${src_dir}/target/${artifact_id}-${version}"

HERE=$(dirname "$0")
"$HERE/../rename.sh" "$IMAGE" "$API_CONTAINER" force

# Asserting a ./Dockerfile like:
# FROM aws-eb-glassfish:5.0-al-onbuild-2.11.1
# ADD conf /tmp/conf
# RUN cp \
#     ./WEB-INF/lib/mysql-*.jar \
#     ${GLASSFISH_HOME}/glassfish/domains/domain1/lib
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
