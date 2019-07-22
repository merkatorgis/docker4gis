#!/bin/bash

export MSYS_NO_PATHCONV=1

src_volume="$1"
dst_volume="$2"

docker volume create "${dst_volume}" > /dev/null

docker container run \
	--name docker-volume-mv \
	--rm \
	--mount source="${src_volume}",target=/.src \
	--mount source="${dst_volume}",target=/.dst \
	alpine \
	sh -c ' # https://unix.stackexchange.com/a/6397
		for x in /.src/* /.src/.[!.]* /.src/..?*
		do
			if [ -e "$x" ]
			then
				mv -- "$x" /.dst/
			fi
		done
	'

if ! docker volume rm "${src_volume}" > /dev/null
then
	echo ' -> i.e. content is moved, but source volume remains to be removed manually'
fi
