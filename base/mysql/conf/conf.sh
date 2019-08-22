#!/bin/bash
set -e

script="$1"

if [ ! "${script}" ]; then
	echo "
		export MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
		export MYSQL_HOST=${CONTAINER}
		export MYSQL_DATABASE=${MYSQL_DATABASE}
	" > /secrets/.mysql
	
	echo "
		[client]
		password=${MYSQL_ROOT_PASSWORD}
		host=${CONTAINER}
	" > /secrets/.mysql.options

	mysql.sh -e "
		create user 'root'@'${GATEWAY}' identified by '${MYSQL_ROOT_PASSWORD}';
		grant all on *.* to 'root'@'${GATEWAY}';
	" &

	find $(dirname "$0") -name 'conf.sh' -mindepth 2 -exec "$0" {} \; &
else # all lower-level conf.sh scripts (in the backgroud, allowing to wait for the db firing up)
	pushd $(dirname "${script}") >/dev/null
	set +e
	"${script}"
	set -e
	popd >/dev/null
fi
