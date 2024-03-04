#!/bin/bash

options=/.mysql.options

[ -f "$options" ] || echo "
	[client]
	password=${MYSQL_ROOT_PASSWORD}
	host=${MYSQL_HOST:-$DOCKER_USER-mysql}
" >"$options"

# Wait until the database is ready.
while ! mysql --defaults-extra-file="$options" -e "select 1" 1>/dev/null 2>&1; do
	sleep 1
done

force=$1
if [ "$force" = force ]; then
	shift 1
	# force = must succeed.
	while ! mysql --defaults-extra-file="$options" "$@"; do
		sleep 1
	done
else
	mysql --defaults-extra-file="$options" "$@"
fi
