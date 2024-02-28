#!/bin/bash

set -x

no_client=$1

if ! which runner.sh; then
	echo "ERROR: install the runner plugin, required by the pg plugin" >&2
	exit 1
fi

if [ "$no_client" != no_client ]; then
	if which apk; then
		apk update
		apk add --no-cache postgresql-client
	else
		apt update
		apt install -y postgresql-client
	fi
fi

here=$(dirname "$0")

mv "$here"/pg.sh "$here"/refresh.sh /usr/local/bin
