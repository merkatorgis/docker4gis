#!/bin/bash
set -e

# if @buildtime, save for runtime
if ! [ "$DOCKER_USER" ]; then
	echo "$0" "$@" >>/onstart
	exit
fi

user=${1}
script=$(realpath "$2")
shift 2

addmailbox.sh "$user"

conf="${script}.conf"
[ -f "${conf}" ] || echo '#!/bin/bash' >"${conf}"
chmod +x "$conf"
"$conf" "$user"

logdir="/util/runner/log/$DOCKER_USER/$user$(dirname "${script}")"
mkdir -p "$logdir"
chown --recursive "$user" "$logdir"

# see /entrypoint
runner=$DOCKER_USER

echo "${user}   unix  -       n       n       -       -       pipe
      user=${user} argv=/usr/local/bin/$runner ${script} $*" >>/etc/postfix/master.cf

postconf -e 'transport_maps=hash:/etc/postfix/transport'

echo "${user}@${DESTINATION} ${user}:" >>/etc/postfix/transport
postmap /etc/postfix/transport
postfix reload
