#!/bin/bash
set -e

# e.g. /klic/scripts/insert.sh
script="$1"

# e.g. '*/1 * * * *' (or 'startup')
schedule="$2"

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
