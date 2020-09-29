#!/bin/bash

if which apk; then
	apk update
	apk add --no-cache mysql-client
fi

cp "$(dirname "$0")"/mysql.sh /usr/local/bin
