#!/bin/bash

if ! which runner.sh
then
	echo "ERROR: install the runner plugin, required by the pg plugin" >&2
	exit 1
fi

apk update; apk add --no-cache postgresql-client

here=$(dirname "$0")

mv "${here}/pg.sh" "${here}/refresh.sh" /usr/local/bin
rm -rf "${here}"
