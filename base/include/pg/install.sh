#!/bin/bash

apk update; apk add --no-cache postgresql-client

here=$(dirname "$0")
mkdir -p /util

if ! [ -f /util/runner.sh ]; then
	"${here}/../runner/install.sh"
fi

mv "${here}/pg.sh" "${here}/refresh.sh" /util/
rm -rf "${here}"
