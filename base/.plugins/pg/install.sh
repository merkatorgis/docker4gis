#!/bin/bash

set -x

if ! which runner.sh; then
	echo "ERROR: install the runner plugin, required by the pg plugin" >&2
	exit 1
fi

if which apk; then
	apk update
	apk add --no-cache postgresql-client
else
	apt update
	apt install -y postgresql-client
fi

here=$(dirname "$0")

mv "$here"/pg.sh "$here"/refresh.sh /usr/local/bin
