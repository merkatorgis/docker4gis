#!/bin/bash
set -e

user="${1}"
script="${2}"
shift 2

if ! getent passwd | grep "^${user}:"; then
	addmailbox.sh "${user}"
fi

conf="${script}.conf"
if [ ! -f "${conf}" ]
then
	echo '#!/bin/bash' > "${conf}"
fi
dir=$(dirname "${script}")
logdir="/util/runner/log${dir}"
echo mkdir -p "${logdir}" >> "${conf}"
echo chown "${user}" "${logdir}" >> "${conf}"

echo "${user}   unix  -       n       n       -       -       pipe
      user=${user} argv=/usr/local/bin/runner.sh ${script} $@" >> /etc/postfix/master.cf

postconf -e 'transport_maps=hash:/etc/postfix/transport'

if postfix status; then
	# Run time, ${DESTINATION} known
	echo "${user}@${DESTINATION} ${user}:" >> /etc/postfix/transport
	postmap /etc/postfix/transport
	"${conf}"
	postfix reload
else
	# Build time, ${DESTINATION} prone to change
	echo "${user}@{{DESTINATION}} ${user}:" >> /etc/postfix/transport.template
	echo "${conf}" >> /onstart
fi
