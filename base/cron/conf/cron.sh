#!/bin/bash
set -e

# e.g. '*/1 * * * *' (or 'startup')
schedule="$1"

# e.g. /klic/scripts/insert.sh
script="$2"

# pass 'startup' to run on container startup as well
startup="$3"

shift 2
if [ "${startup}" = 'startup' ]; then
	shift 1
fi

if [ "${schedule}" = 'startup' -o "${startup}" = 'startup' ]; then
	echo "runner.sh '${script}' $@" >> /util/cron/startup.sh
fi

if [ "${schedule}" != 'startup' ]; then
	(crontab -l 2>/dev/null; echo "${schedule} runner.sh '${script}' $@") | crontab -
fi
