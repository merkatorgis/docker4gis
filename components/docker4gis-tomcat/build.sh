#!/bin/bash

MAVEN_TAG=v0.0.9

build() {
	docker image build \
		--build-arg DOCKER_USER="$DOCKER_USER" \
		-t "$IMAGE" .
}

pom=$(find . -maxdepth 2 -name pom.xml | head -n 1)
if [ "$pom" ]; then
	# Building an extension image from Java sources; using docker4gis/maven to
	# compile them to a .war file, then deploy the .war file.
	src_dir=$(dirname "$pom")
	src_dir=$(realpath "$src_dir")
	project_name=$(basename "$src_dir")
	# Use .docker4gis.sh to copy the image's own version of docker4gis out
	# of the image.
	temp=$(mktemp -d)
	dotdocker4gis=$BASE
	dotdocker4gis=${dotdocker4gis:-$(dirname "$0")}
	dotdocker4gis=$("$dotdocker4gis"/docker4gis/.docker4gis.sh "$temp" docker4gis/maven:"$MAVEN_TAG")
	(
		cd "$dotdocker4gis" || exit
		# The values of the env vars on the line below only prevail for the maven
		# run; onwards, they still have the value they have now.
		DOCKER_REGISTRY='docker.io' DOCKER_USER=docker4gis \
			docker4gis/run.sh maven "$MAVEN_TAG" "$src_dir" || exit 1
	)
	rm -rf "$temp"
	echo
	# This is the location where `/entrypoint` will find it.
	webapps_dir=conf/webapps
	mkdir -p "$webapps_dir"
	cp "$src_dir"/target/*.war "$webapps_dir/$project_name.war"
	build
	rm -rf "$webapps_dir"
else
	# Either building the base image, or an extension image with (a) precompiled
	# webapp(s).
	build
fi
