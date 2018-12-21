#!/bin/bash

# In verschillende sessies:
# $ top
# $ docker container exec -ti geowep-pg top
# $ tail -f /docker/binds/runner/util/runner/util/refresh.sh.2018-07-03.log
# $ docker container exec geowep-pg refresh.sh run interpolatie.mv_sonderingen_lagen &


if [ "$1" = 'run' ]; then
	shift 1
	exec runner.sh "$0" "$@"
else
	taskid="$1"
	mv="$2"
	what="${mv}"
	if pg.sh -c "select from ${mv} limit 0" 1>/dev/null 2>&1; then
		what="concurrently ${mv}"
	fi
	echo "${taskid} refreshing ${what}..."
	if pg.sh -c "refresh materialized view ${what}"; then
		echo "${taskid} refreshing ${what}... done"
		exit 0
	else
		echo "${taskid} refreshing ${what}... failed"
		exit 1
	fi
fi
