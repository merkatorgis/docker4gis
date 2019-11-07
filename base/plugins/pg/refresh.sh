#!/bin/bash

# In verschillende sessies:
# $ top
# $ docker container exec -ti myapp-pg top
# $ tail -f /root/docker-binds/runner/util/refresh.sh.2019-05-29.log
# $ docker container exec myapp-pg refresh.sh run schema.mv_matviewname &

refresh()
{
	what="$1"
	message="${taskid} refreshing ${what}..."
	echo "${message}"
	if pg.sh -c "refresh materialized view ${what}"; then
		echo "${message}... done"
		echo 0
	else
		echo "${message}... failed"
		echo 1
	fi
}

if [ "$1" = 'run' ]; then
	shift 1
	exec runner.sh "$0" "$@"
else
	taskid="$1"
	mv="$2"
	force="$3"
	if ! pg.sh -c "select from ${mv} limit 0" 1>/dev/null 2>&1; then
		refresh "${mv}"
	elif ! refresh "concurrently ${mv}" && [ "${force}" == 'force' ]; then
		refresh "${mv}"
	fi
fi
