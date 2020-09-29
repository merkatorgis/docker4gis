#!/bin/bash
set -e

# e.g. '*/1 * * * *' (or 'startup')
schedule=$1

# e.g. /klic/scripts/insert.sh
script=$2

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
