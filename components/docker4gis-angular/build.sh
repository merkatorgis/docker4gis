#!/bin/bash

function src() {
	angular_json=$(find . -name angular.json | head -n 1)
	SRC=$(dirname "$angular_json")
	[ -n "$angular_json" ]
}

here=$(dirname "$0")

# If we're building not the base component, but an extension image, and there's
# no angular.json, then we create a new Angular project.
if ! [ "${DOCKER_USER:?}" = "docker4gis" ] && ! src; then
	app="$DOCKER_USER-app"
	which ng || npm install -g @angular/cli &&
		# Create a new Angular project, skipping git initialization.
		ng new "$app" --skip-git true &&
		src || exit &&

		# https://angular.dev/ai/develop-with-ai#rules-files
		cp -r "$here/conf/app/." "$app" &&

		# https://angular.dev/ai/agent-skills
		pushd "$app" &&
		npx skills add https://github.com/angular/skills --skill '*' --yes &&
		popd || exit
fi

docker image build \
	--build-arg DOCKER_USER="$DOCKER_USER" \
	--build-arg SRC="$SRC" \
	-t "$IMAGE" .
