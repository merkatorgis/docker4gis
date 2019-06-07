#!/bin/bash

user="${1}"
script="${2}"
shift 2

if ! getent passwd | grep "^${user}:"; then
	addmailbox.sh "${user}"
fi

logdir="/util/runner/log/$(dirname ${script})"
mkdir -p "${logdir}"
chown "${user}" "${logdir}"

echo "${user}   unix  -       n       n       -       -       pipe
      user=${user} argv=/util/runner.sh ${script} $@" >> /etc/postfix/master.cf

postconf -e 'transport_maps=hash:/etc/postfix/transport'

conf="${script}.conf"
touch "${conf}"
if postfix status; then
	# Run time, ${DESTINATION} known
	echo "${user}@${DESTINATION} ${user}:" >> /etc/postfix/transport
	postmap /etc/postfix/transport
	. "${conf}"
	postfix reload
else
	# Build time, ${DESTINATION} prone to change
	echo "${user}@{{DESTINATION}} ${user}:" >> /etc/postfix/transport.template
	echo ". ${conf}" >> /onstart
fi
