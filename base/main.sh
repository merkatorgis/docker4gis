#!/bin/bash

# Uncomment next lines for debugging the commands that are issued:
# echo
# echo " -- main.sh $* --"
# echo
# set -x

DOCKER_BASE=$(realpath "$(dirname "$0")")
export DOCKER_BASE

DOCKER_BINDS_DIR=$(realpath ~)/docker-binds
export DOCKER_BINDS_DIR

export DOCKER_REGISTRY=$DOCKER_REGISTRY
export DOCKER_USER=$DOCKER_USER
export DOCKER_REPO=$DOCKER_REPO

export DOCKER_ENV=DEVELOPMENT

export PROXY_HOST=${PROXY_HOST:-localhost}
export PROXY_PORT=${PROXY_PORT:-7443}
export PROXY_PORT_HTTP=${PROXY_PORT_HTTP:-7780}
export APP=$APP
export API=$API
export HOMEDEST=$HOMEDEST

export TZ=$TZ

export PGHOST=$PGHOST
export PGHOSTADDR=$PGHOSTADDR
export PGPORT=$PGPORT
export PGDATABASE=$PGDATABASE
export PGUSER=$PGUSER
export PGPASSWORD=$PGPASSWORD

export MYSQL_HOST=$MYSQL_HOST
export MYSQL_DATABASE=$MYSQL_DATABASE
export MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD

export POSTFIX_DESTINATION=$POSTFIX_DESTINATION
export POSTFIX_DOMAIN=$POSTFIX_DOMAIN

export MSYS_NO_PATHCONV=1

docker >/dev/null 2>&1 || {
	err_code=$?
	echo "Command \`docker\` failed; is Docker running?"
	exit "$err_code"
}

dir=$1
action=$2
shift 2

this() {
	"$0" "$dir" "$@"
}

# shellcheck disable=SC1091
source "$DOCKER_BASE"/dotenv.bash

dir() {
	# If the first argument is a docker4gis component/package directory, perform
	# the current action in the given component/package directory, with the
	# given parameters.
	repo=$1
	shift 1
	if [ "$repo" ] && ! [ "$repo" = "$DOCKER_REPO" ]; then
		# Use a file-based mechanism to enable signalling from the subshell
		# below.
		dir_found=$(mktemp)
		rm "$dir_found"
		for env_file in ../*/.env; do
			[ -f "$env_file" ] || break
			(
				dotenv forgiving "$env_file"
				if [ "$repo" = "$DOCKER_REPO" ]; then
					dir=$(dirname "$env_file")
					# Signal.
					touch "$dir_found"
					# echo " ! cd to $dir"
					cd "$dir" || exit 1

					installed_docker4gis="$DOCKER_BASE"/../../.bin/docker4gis
					if [ -x "$installed_docker4gis" ]; then
						# Use the .bin-version if it exists, so that docker4gis
						# will detect that it's an installed version.
						docker4gis=$installed_docker4gis
					else
						# Otherwise, it should be the case that we're running
						# from a git clone, where the source script resides in
						# the root directory, one below the /base directory.
						docker4gis="$DOCKER_BASE"/../docker4gis
					fi
					"$docker4gis" "$action" "$@"
				fi
			)
			ret=$?
		done
		if [ -f "$dir_found" ]; then
			rm -f "$dir_found"
			exit "$ret"
		fi
	fi
}

case "$action" in

build)
	dir "$@"
	if [ "$DOCKER_REPO" = package ] || this test; then
		"$DOCKER_BASE/.docker4gis/docker4gis/build.sh" "$@"
	else
		echo
		echo "Not starting the build, since one or more tests failed".
		exit 1
	fi
	;;

unbuild)
	dir "$@"
	docker image rm -f "$DOCKER_REGISTRY/$DOCKER_USER/$DOCKER_REPO:latest"
	;;

run)
	dir package "$@"
	tag=$1
	if [ "$tag" ]; then
		eval "$(docker container run --rm "$DOCKER_REGISTRY"/"$DOCKER_USER"/package:"$tag")"
	else
		if runscript=$(BASE=$DOCKER_BASE/.docker4gis "$DOCKER_BASE"/package/list.sh dirty); then
			eval "$runscript" && echo &&
				docker container ls
		else
			false
		fi
	fi && echo && this test
	;;

br)
	this build "$@" && echo &&
		this run
	;;

push)
	dir "$@"
	"$DOCKER_BASE/push.sh" "$@"
	;;

test)
	"$DOCKER_BASE/test.sh" "$@"
	;;

stop)
	"$DOCKER_BASE/stop.sh"
	;;

geoserver)
	container=$DOCKER_USER-$DOCKER_REPO
	eval "$(docker container exec "$container" dg geoserver)"
	;;

*)
	echo "Unknown action: $action"
	;;

esac
