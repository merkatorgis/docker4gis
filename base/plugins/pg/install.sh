#!/bin/bash

apk update; apk add --no-cache postgresql-client

here=$(dirname "$0")

if ! which runner.sh
then
	"${here}/../runner/install.sh"
fi

mv "${here}/pg.sh" "${here}/refresh.sh" /usr/local/bin
rm -rf "${here}"
