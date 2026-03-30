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
echo "Building Docker image $DOCKER_IMAGE..."
docker image build -t "$DOCKER_IMAGE" "$(dirname "$0")" >"$out" 2>"$err" || failed=true
[ -f "$err" ] && rm "$err"
[ -z "$failed" ] || exit 1

# Clean up.
rm -rf "$docker4gis_dir"

find_root_env() {
	# Walk up from cwd looking for a .env with DOCKER4GIS_ROOT=true.
	local dir
	dir=$(realpath .)
	while [ "$dir" != "/" ]; do
		if grep -q "^DOCKER4GIS_ROOT=true" "$dir/.env" 2>/dev/null; then
			echo "$dir/.env"
			return 0
		fi
		dir=$(dirname "$dir")
	done
	return 1
}

root_env_file=$(find_root_env) || true

if [ -n "$root_env_file" ]; then
	# Strip optional surrounding single quotes (values may be quoted for space-safety).
	read_root_env() { grep "^$1=" "$root_env_file" 2>/dev/null | cut -d= -f2- | sed "s/^'//;s/'$//"; }
	DOCKER_USER=$(read_root_env DOCKER_USER)
	DOCKER_REGISTRY=$(read_root_env DOCKER_REGISTRY)
	DEVOPS_ORGANISATION=$(read_root_env DEVOPS_ORGANISATION)
	DEVOPS_DEFAULT_POOL=$(read_root_env DEVOPS_DEFAULT_POOL)
	DEVOPS_VPN_POOL=$(read_root_env DEVOPS_VPN_POOL)
fi

root_env_mount=()
[ -n "$root_env_file" ] && root_env_mount=(
	--mount "type=bind,source=$root_env_file,target=/devops/root_env_file"
)

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
	"${root_env_mount[@]}" \
	--env DEBUG="$DEBUG" \
	--env DOCKER_USER="$DOCKER_USER" \
	--env DOCKER_REGISTRY="$DOCKER_REGISTRY" \
	--env DEVOPS_ORGANISATION="$DEVOPS_ORGANISATION" \
	--env DEVOPS_DEFAULT_POOL="$DEVOPS_DEFAULT_POOL" \
	--env DEVOPS_VPN_POOL="$DEVOPS_VPN_POOL" \
	--env ROOT_ENV_FILE="${root_env_file:+/devops/root_env_file}" \
	--env ENV_FILE="$container_env_file" \
	--mount type=bind,source="$ENV_FILE",target="$container_env_file" \
	--mount type=bind,source="$docker_socket",target="$docker_socket" \
	"$DOCKER_IMAGE" "$@" || exit
