#!/bin/sh

if ! which runner.sh
then
	echo "ERROR: install the runner plugin, required by the mail plugin" >&2
	exit 1
fi

apk update; apk add --no-cache \
	mailx rsyslog postfix shadow bash gettext

# prevent "postdrop: warning: unable to look up public/pickup: No such file or directory"
mkfifo /var/spool/postfix/public/pickup

here=$(dirname "$0")

cp "${here}/postfix.sh" /usr/local/bin
cp "${here}/addmailbox.sh" /usr/local/bin
cp "${here}/mail.sh" /usr/local/bin

echo 'NOTICE: Run `postfix.sh` on container startup'
echo 'NOTICE: Run eg `addmailbox.sh user name` on image build or later, eg: 
	`addmailbox.sh noreply "Example.com Template Service"`'
echo 'NOTICE: Run `echo message | mail.sh to_address subject [from_user default noreply]` to send mail.
	Environment variables in subject and message are substituted.'
