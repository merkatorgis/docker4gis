#!/bin/bash
set -e

echo "
	export MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
	export MYSQL_HOST=${CONTAINER}
	export MYSQL_DATABASE=${MYSQL_DATABASE}
" >/secrets/.mysql

echo "
	[client]
	password=${MYSQL_ROOT_PASSWORD}
	host=${CONTAINER}
" >/secrets/.mysql.options

mysql.sh -e "
	create user 'root'@'${GATEWAY}' identified by '${MYSQL_ROOT_PASSWORD}';
	grant all on *.* to 'root'@'${GATEWAY}';
" &

find /tmp/conf -name "conf.sh" -exec /tmp/subconf.sh {} \; &
