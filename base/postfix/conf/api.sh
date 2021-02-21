#!/bin/bash
set -e

user=${1}
script=$(realpath "$2")
shift 2

addmailbox.sh "$user"

conf="${script}.conf"
[ -f "${conf}" ] || echo '#!/bin/bash' >"${conf}"
chmod +x "$conf"

logdir="/util/runner/log/$DOCKER_USER/$user$(dirname "${script}")"
# if at build time, the next commands are postponed to run time, since the
# logdir path is mapped the host; it doesn't reside inside the image
{
	echo mkdir -p "$logdir"
	echo chown --recursive "$user" "$logdir"
} >>"$conf"

# see /entrypoint
runner=$DOCKER_USER

echo "${user}   unix  -       n       n       -       -       pipe
      user=${user} argv=/usr/local/bin/$runner ${script} $*" >>/etc/postfix/master.cf

postconf -e 'transport_maps=hash:/etc/postfix/transport'

if postfix status; then
	# Run time, ${DESTINATION} known
	echo "${user}@${DESTINATION} ${user}:" >>/etc/postfix/transport
	postmap /etc/postfix/transport
	"$conf" "$user"
	postfix reload
else
	# Build time, ${DESTINATION} prone to change
	echo "${user}@{{DESTINATION}} ${user}:" >>/etc/postfix/transport.template
	echo "$conf" "$user" >>/onstart
fi
