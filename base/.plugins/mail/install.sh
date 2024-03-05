#!/bin/sh

if which apk; then # Alpine
	apk update
	apk add --no-cache \
		mailx rsyslog postfix shadow bash gettext
fi

if which apt; then # Debian?
	apt update
	apt install -y sudo
	DEBIAN_FRONTEND=noninteractive apt install -y postfix
	# for `mail`
	apt install -y mailutils
	# for `envsubst`
	apt install -y gettext-base
fi

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
