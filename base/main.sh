#!/bin/bash

# Uncomment for debugging the commands that are issued:
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
export SECRET=$SECRET
export APP=$APP
export API=$API
export HOMEDEST=$HOMEDEST

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

dir() {
	# Perform the current action in the given component/package directory, with
	# the given parameters.
	repo=$1
	shift 1
	if [ "$repo" ] && ! [ "$repo" = "$DOCKER_REPO" ]; then
		dir_found=$(mktemp)
		rm "$dir_found"
		for env_file in ../*/.env; do
			[ -f "$env_file" ] || break
			(
				# shellcheck source=/dev/null
				. "$env_file"
				if [ "$repo" = "$DOCKER_REPO" ]; then
					dir=$(dirname "$env_file")
					touch "$dir_found"
					# echo " ! cd to $dir"
					cd "$dir" || exit 1
					"$DOCKER_BASE"/../docker4gis "$action" "$@"
				fi
			)
		done
		if [ -f "$dir_found" ]; then
			rm "$dir_found"
			exit 0
		else
			echo "Cannot find directory for $repo."
			exit 1
		fi
	fi
}

case "$action" in
build)
	dir "$1"
	this test &&
		"$DOCKER_BASE/.docker4gis/docker4gis/build.sh"
	;;
run)
	dir package "$@"
	tag=$1
	if [ "$tag" ]; then
		eval "$(docker container run --rm "$DOCKER_REGISTRY"/"$DOCKER_USER"/package:"$tag")"
	else
		if runscript=$("$DOCKER_BASE"/package/list.sh dirty); then
			eval "$runscript" && echo &&
				docker container ls
		else
			false
		fi
	fi && echo && this test
	;;
br)
	this build "$1" && echo &&
		this run
	;;
push)
	dir "$1"
	"$DOCKER_BASE/push.sh"
	;;
test)
	dir "$1"
	"$DOCKER_BASE/test.sh"
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
