#!/bin/bash

. /secrets/.mysql

while ! mysql -h "${MYSQL_HOST}" "-p${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" -e "select 1" 1>/dev/null 2>&1
do
	sleep 1
done

force="$1"
if [ "${force}" = 'force' ]
then
	shift 1
	while ! mysql -h "${MYSQL_HOST}" "-p${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" "$@"
	do
		sleep 1
	done
else
	mysql -h "${MYSQL_HOST}" "-p${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" "$@"
fi
