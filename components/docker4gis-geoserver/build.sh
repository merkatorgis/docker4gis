#!/bin/bash

docker image build \
	--build-arg DOCKER_REGISTRY="$DOCKER_REGISTRY" \
	--build-arg DOCKER_USER="$DOCKER_USER" \
	--build-arg DOCKER_REPO="$DOCKER_REPO" \
	--build-arg STABLE_EXTENSIONS="$STABLE_EXTENSIONS" \
	--build-arg COMMUNITY_EXTENSIONS="$COMMUNITY_EXTENSIONS" \
	--build-arg POSTGRES_HOST="$POSTGRES_HOST" \
	--build-arg POSTGRES_PORT="$POSTGRES_PORT" \
	--build-arg POSTGRES_DB="$POSTGRES_DB" \
	--build-arg POSTGRES_USERNAME="$POSTGRES_USERNAME" \
	--build-arg POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
	-t "$DOCKER_IMAGE" . &&
	docker container run --rm \
		--mount src="$(realpath conf/additional_libs)",target=/save_additional_libs/,type=bind \
		"$DOCKER_IMAGE" \
		/opt/additional_libs/save_additional_libs.sh
