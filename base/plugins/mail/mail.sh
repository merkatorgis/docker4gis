#!/bin/bash

to="$1"
subject=$(echo "$2" | envsubst)
login="${3:-noreply}"

message=$(mktemp)
cat | envsubst > "${message}"

sudo -u "${login}" mail -s "$subject" "$to" < "${message}"

rm -f "${message}"
