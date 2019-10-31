#!/bin/sh

apk update; apk add --no-cache \
	mailx rsyslog postfix shadow

# postdrop: warning: unable to look up public/pickup: No such file or directory
mkfifo /var/spool/postfix/public/pickup

here=$(dirname "$0")
cp "${here}/addmailbox.sh" /usr/local/bin
cp "${here}/mail.sh" /usr/local/bin

echo 'NOTICE: Run `postfix start` on container startup'
echo 'NOTICE: Run eg `addmailbox.sh noreply "Merkator DXF-service"` on image build or later'
