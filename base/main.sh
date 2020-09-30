#!/bin/bash

DOCKER_BASE=$(realpath "$(dirname "$0")")
export DOCKER_BASE

DOCKER_BINDS_DIR=$(realpath "$DOCKER_BASE/../binds")
export DOCKER_BINDS_DIR

export DOCKER_REGISTRY=$DOCKER_REGISTRY
export DOCKER_USER=$DOCKER_USER

export DOCKER_ENV=DEVELOPMENT

export PROXY_HOST=${PROXY_HOST:-localhost}
export PROXY_PORT=${PROXY_PORT:-7443}
export SECRET=$SECRET
export APP=$APP
export API=$API
export HOMEDEST=$HOMEDEST

export POSTFIX_DESTINATION=$POSTFIX_DESTINATION
export POSTFIX_DOMAIN=$POSTFIX_DOMAIN

export MSYS_NO_PATHCONV=1

mainscript=$1
action=$2
shift 2

DOCKER_APP_DIR=$(realpath "$(dirname "$mainscript")")
export DOCKER_APP_DIR

this() {
	"$0" "$mainscript" "$@"
}

case "$action" in
build)
	repo=$1
	[ "$repo" ] || echo "Please pass the name of the component to build."
	[ "$repo" ] && this test "$repo" &&
		"$DOCKER_BASE/.docker4gis/docker4gis/build.sh" "$repo"
	;;
run)
	tag=$1
	if [ "$tag" ]; then
		eval "$(docker container run --rm "$DOCKER_REGISTRY""$DOCKER_USER"/package:"$tag")"
	else
		eval "$(BASE=$DOCKER_BASE/.docker4gis "$DOCKER_BASE"/package/list.sh dirty)" && echo &&
			docker container ls
	fi && echo &&
		this test
	;;
br)
	this build "$1" && echo &&
		this run
	;;
latest)
	eval "$(BASE=$DOCKER_BASE/.docker4gis "$DOCKER_BASE"/package/list.sh latest)" && echo &&
		docker container ls
	;;
push)
	repo=$1
	tag=$2
	"$DOCKER_BASE/push.sh" "$repo" "$tag" || exit 1
	[ "$tag" ] || exit 0 &&
		"$DOCKER_BASE/.docker4gis/docker4gis/build.sh" .package &&
		"$DOCKER_BASE/push.sh" .package "$tag"
	;;
test)
	"$DOCKER_BASE/test.sh" "$1"
	;;
stop)
	"$DOCKER_BASE/stop.sh"
	;;
geoserver)
	app_name=${1:-$DOCKER_USER}
	container=$DOCKER_USER-geoserver
	data_dir=$(docker container exec "$container" bash -c 'echo "$GEOSERVER_DATA_DIR"')
	from=$container:$data_dir/workspaces/$app_name
	to=geoserver/conf/$app_name/workspaces
	echo "About to overwrite './$to/$app_name' with '$from'"
	read -rn 1 -p 'Press any key to continue (or Ctrl-C to cancel)...'
	echo
	rm -rf "${to:?}/$app_name"
	docker container cp "$from" "$to"
	;;
*)
	echo "Unknown action: $action"
	;;
esac
