#!/bin/bash
set -e

# e.g. '* * * * *' (or 'startup')
schedule=$1

# e.g. /klic/scripts/insert.sh
script=$2
# Note that you should create a custom script file for each task. The script is
# run by runner.sh, which passes the process ID as the first argument, followed
# by the extra arguments given to cron.sh. These arguments should not contain
# spaces.

# pass 'startup' to run on container startup as well
startup=$3

shift 2
[ "$startup" = startup ] &&
	shift 1

[ "$schedule" = startup ] || [ "$startup" = startup ] &&
	echo "runner.sh '$script' $*" >>/util/cron/startup.sh

[ "$schedule" = startup ] || (
	crontab -l 2>/dev/null
	echo "$schedule runner.sh '$script' $*"
) | crontab -
