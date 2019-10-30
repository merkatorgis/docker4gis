#!/bin/bash

export RELAYHOST="${1:-${DOCKER_USER}-postfix}"

apk update; apk add --no-cache \
	mailx rsyslog postfix

# postdrop: warning: unable to look up public/pickup: No such file or directory
mkfifo /var/spool/postfix/public/pickup

echo '#!/bin/sh
from=$1
to=$2
subject=$3
mail -s "$subject" $to - -f $from
' > /usr/local/bin/mail.sh
chmod +x /usr/local/bin/mail.sh
