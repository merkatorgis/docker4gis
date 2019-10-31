#!/bin/sh

to=$1
subject=$2
login=${3:-noreply}

message=$(mktemp)
cat > "${message}"

sudo -u "${login}" mail -s "$subject" $to < "${message}"

rm -f "${message}"
