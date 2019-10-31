#!/bin/sh

to=$1
subject=$2
login=$3

message=$(mktemp)
cat > "${message}"

if [ "${login}" ]
then
    sudo -S -u "${login}" mail -s "$subject" $to < "${message}"
else
    mail -s "$subject" $to < "${message}"
fi

rm -f "${message}"
