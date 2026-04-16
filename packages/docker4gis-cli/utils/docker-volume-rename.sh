#!/bin/bash
set -e

export MSYS_NO_PATHCONV=1

src_volume=$1
dst_volume=$2

docker volume create "${dst_volume}"

docker container run \
	--name docker-volume-mv \
	--rm \
	--mount source="${src_volume}",target=/.src \
	--mount source="${dst_volume}",target=/.dst \
	alpine \
	sh -c ' # https://unix.stackexchange.com/a/6397
		shopt -s dotglob
		mv /.src/* /.dst/
	'

if ! docker volume rm "${src_volume}" >/dev/null; then
	echo ' -> i.e. content is moved, but source volume remains to be removed manually'
fi
