#!/bin/bash

apk add --no-cache \
	freetds

template=$(mktemp)

echo '[TDS]
Description = FreeTDS for connecting to Sybase and SQL Server
Driver      = /usr/lib/libtdsodbc.so.0' > "${template}"

odbcinst -i -d -f "${template}"

rm -rf "${template}" $(dirname "$0")
