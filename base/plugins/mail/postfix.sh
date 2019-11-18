#!/bin/bash

ID="$1"
if [ ! "${ID}" ]
then
    runner.sh "$0" &
    exit
fi

myhostname="${POSTFIX_DOMAIN:-${HOSTNAME}}"
postconf -e myhostname="${myhostname}"

while true
do
    if ! postfix status
    then
        echo "${ID} $(date -Ins) start ${myhostname} $(
            postfix start
        )"
    fi
    sleep 5
done
