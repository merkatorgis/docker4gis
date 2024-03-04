#!/bin/bash

# set -x

# In verschillende sessies:
# $ top
# $ docker container exec -ti myapp-pg top
# $ tail -f /root/docker-binds/runner/util/refresh.sh.2019-05-29.log
# $ docker container exec myapp-pg refresh.sh run schema.mv_matviewname &

log() {
	echo "$PPID" "$@"
}

refresh() {
	what=$1
	message="refreshing $what..."
	log "$message"
	finish() {
		local err=$1
		local result='done'
		[ "$err" = 0 ] || result=failed
		log "$output"
		log "$message $result"
		return "$err"
	}
	output=$(pg.sh -c "refresh materialized view $what" 2>&1)
	finish "$?"
}

if [ "$1" = run ]; then
	shift 1
	exec runner.sh "$0" "$@"
else
	mv=$1
	force=$2
	if ! pg.sh -c "select from $mv limit 0" 1>/dev/null 2>&1; then
		refresh "$mv"
	elif ! refresh "concurrently $mv" && [ "$force" = force ]; then
		refresh "$mv"
	fi
fi
