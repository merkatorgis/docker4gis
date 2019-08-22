#!/bin/bash

while ! mysql --defaults-extra-file=/secrets/.mysql.options -e "select 1" 1>/dev/null 2>&1
do
	sleep 1
done

force="$1"
if [ "${force}" = 'force' ]
then
	shift 1
	while ! mysql --defaults-extra-file=/secrets/.mysql.options "$@"
	do
		sleep 1
	done
else
	mysql --defaults-extra-file=/secrets/.mysql.options "$@"
fi
