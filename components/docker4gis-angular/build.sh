#!/bin/bash

function src() {
	angular_json=$(find . -name angular.json | head -n 1)

	# Set the SRC directory, which is needed as a Docker build-arg.
	SRC=$(dirname "$angular_json")

	# Return true if angular.json is found, false otherwise.
	[ -f "$angular_json" ]
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
		(
			cd "$app" &&

				# https://angular.dev/ai/develop-with-ai#rules-files
				cp -r "$here/conf/app/." ./ &&

				# https://angular.dev/ai/agent-skills
				npx skills add https://github.com/angular/skills --skill '*' --yes &&

				# https://goo.gle/modern-web-guidance
				npx skills add GoogleChrome/modern-web-guidance --skill '*' --yes
		)
fi

docker image build \
	--build-arg DOCKER_USER="$DOCKER_USER" \
	--build-arg SRC="$SRC" \
	-t "$IMAGE" .
