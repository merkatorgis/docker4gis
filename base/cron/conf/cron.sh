#!/bin/bash
set -e

# e.g. '* * * * *' (or 'startup')
schedule=$1

# e.g. /klic/scripts/insert.sh
script=$2

# pass 'startup' to run on container startup as well
startup=$3

shift 2
[ "$startup" = startup ] &&
	shift 1

# Preserve quoted arguments with spaces; see
# https://www.gnu.org/software/bash/manual/bash.html#index-printf.
args=$(printf '%q ' "$@")

format() {
	echo "runner.sh '$script' $args"
}

[ "$schedule" = startup ] || [ "$startup" = startup ] &&
	format >>/util/cron/startup.sh

[ "$schedule" = startup ] || (
	crontab -l 2>/dev/null
	echo "$schedule" "$(format)"
) | crontab -
