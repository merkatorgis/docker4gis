#!/bin/bash
set -e
set -x

# e.g. '* * * * *' (or 'startup')
schedule=$1

# e.g. /klic/scripts/insert.sh
script=$2
# Note that you must create a custom script file for each task. The script is
# run by runner.sh, which passes the extra arguments given to cron.sh. These
# arguments must not contain spaces.

# pass 'startup' to run on container startup as well
startup=$3

shift 2
[ "$startup" = startup ] &&
	shift 1

dir=/cron
mkdir -p "$dir"

# /cron/tmp.LpGlJDdcdy
temp=$(mktemp -p "$dir")
rm -f "$temp"

# tmp.LpGlJDdcdy
file=$(basename "$temp")
# LpGlJDdcdy
file=${file#*.}

lock=$dir/$file
job=$lock.job

echo "#!/bin/bash" >"$job"

if [ "$DEBUG" = true ]; then
	log=$lock.log
	echo "
		echo \$0 \$@ >> '$log'
		env >> '$log'
		echo >> '$log'
	" >>"$job"
	echo "runner.sh '$script' $* >> '$log'" >>"$job"
else
	echo "runner.sh '$script' $*" >>"$job"
fi

chmod +x "$job"

# Use flock to prevent running simultaneous instances of the same cron job. Each
# job gets a unique script and lock file; flock won't start that script if a
# previous job is still running. The generated script ignores the arguments it
# gets; they're only repeated in the crontab so that the user will recognise the
# cron job.

lock=$lock.lock

if [ "$schedule" = startup ] || [ "$startup" = startup ]; then
	echo "flock -n $lock $job '$script' $*" >>/startup.sh
fi

if ! [ "$schedule" = startup ]; then
	{
		crontab -l 2>/dev/null
		echo "$schedule flock -n $lock $job '$script' $*"
	} | crontab -
fi
