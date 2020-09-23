#!/bin/bash
#!/bin/bash
set -e

repo="$1"
tag="$2"
shift 2

src_dir="$1"

DOCKER_REGISTRY="$DOCKER_REGISTRY"
DOCKER_USER="$DOCKER_USER"
DOCKER_ENV="$DOCKER_ENV"
DOCKER_BINDS_DIR="$DOCKER_BINDS_DIR"

container="$DOCKER_USER"-"$repo"
image="$DOCKER_REGISTRY""$DOCKER_USER"/"$repo":"$tag"

docker volume create "$container" >/dev/null
docker container run --rm --name "$container" \
    -v "$(docker_bind_source "$src_dir")":/src \
    --mount source="$container",target=/root/.m2 \
    "$image"
