#!/bin/bash

if which apk
then
	apk update
	apk add --no-cache mysql-client
fi

here=$(dirname "$0")
mkdir -p /util

mv "${here}/mysql.sh" /util/
rm -rf "${here}"
