#!/bin/bash

DEBUG=${DEBUG:-}

here=$(realpath "$(dirname "$0")")

DOCKER_REPO=$(basename "$here")
DOCKER_IMAGE=docker4gis/$DOCKER_REPO
CONTAINER=docker4gis-$DOCKER_REPO

export ENV_FILE=$HOME/.$CONTAINER.env
touch "$ENV_FILE"
chown "$USER" "$ENV_FILE"
chmod 600 "$ENV_FILE"

case "$1" in
set | s)
	shift
	exec "$here"/conf/set.sh "$@"
	;;
components | c)
	shift
	;;
esac

# Set default action.
set -- components "$@"

# Copy the docker4gis tool into the conf directory, so that it can be included
# in the image.
docker4gis_dir=$here/conf/docker4gis
rm -rf "$docker4gis_dir" 2>/dev/null
mkdir "$docker4gis_dir"
find "$here"/.. -maxdepth 1 \
	! -name ".*" \
	! -name node_modules \
	! -name devops \
	-exec cp -r {} "$docker4gis_dir" \;

# Build the image, preventing output if the DEBUG variable is not set (but
# capturing errors).
out=/dev/stdout
[ -z "$DEBUG" ] && out=/dev/null
err=/dev/stderr
[ -z "$DEBUG" ] && err=$(mktemp)
docker image build -t "$DOCKER_IMAGE" "$(dirname "$0")" >"$out" 2>"$err" || failed=true
[ -f "$err" ] && rm "$err"
[ -z "$failed" ] || exit 1

# Clean up.
rm -rf "$docker4gis_dir"

find_docker_user() {
	while read -r env_file; do
		grep "^DOCKER4GIS_VERSION=" "$env_file" &>/dev/null &&
			# The file is in a docker4gis component directory. We need the name
			# of the parent directory.
			DOCKER_USER=$(basename "$(dirname "$(dirname "$env_file")")") &&
			break
		# Find .env files in current directory direct subdirectories (using
		# -print | sort to start with the one in the current directory).
	done < <(find "$(realpath .)" -maxdepth 2 -name ".env" -type f -print | sort)
	[ -z "$DOCKER_USER" ] &&
		# Use the current directory name as a fallback.
		DOCKER_USER=$(basename "$(realpath .)")
}

# Set the DOCKER_USER variable (used as the default value for the DevOps Project
# Name).
[ -n "$DOCKER_USER" ] ||
	find_docker_user

docker_socket=/var/run/docker.sock
container_env_file=/devops/env_file

# Tee all stdout & stderr to a log file (from
# https://superuser.com/a/212436/462952).
[ -n "$DEBUG" ] && exec > >(tee devops.log) 2>&1

# We don't use the --env-file Docker option because it's tricky writing a value
# with spaces back to the file, and then getting it read back in correctly on
# the next container start.
docker container run --name "$CONTAINER" \
	--rm \
	--privileged \
	-ti \
	--env DEBUG="$DEBUG" \
	--env DOCKER_USER="$DOCKER_USER" \
	--env DEVOPS_ORGANISATION="$DEVOPS_ORGANISATION" \
	--env DEVOPS_DOCKER_REGISTRY="$DEVOPS_DOCKER_REGISTRY" \
	--env DEVOPS_VPN_POOL="$DEVOPS_VPN_POOL" \
	--env ENV_FILE="$container_env_file" \
	--mount type=bind,source="$ENV_FILE",target="$container_env_file" \
	--mount type=bind,source="$docker_socket",target="$docker_socket" \
	"$DOCKER_IMAGE" "$@"
