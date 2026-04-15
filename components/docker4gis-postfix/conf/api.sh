#!/bin/bash
set -x

# if @buildtime, save for runtime
if ! [ "$DOCKER_CONTAINER" ]; then
	echo "$0" "$@" >>/onstart
	exit
fi

user=$1
script=$(realpath "$2")
shift 2

addmailbox.sh "$user"

conf=$script.conf
[ -f "$conf" ] || echo '#!/bin/bash' >"$conf"
chmod +x "$conf"
"$conf" "$user"

# Precreate the logdir that runner.sh will use, and have it owned by the user
# that will run the scripts, so that the user can write in it.
logdir=/runner/$user$(dirname "$script")
mkdir -p "$logdir"
chown --recursive "$user:$user" "$logdir"

# see /entrypoint
runner=$DOCKER_USER

echo "$user   unix  -       n       n       -       -       pipe
      user=$user argv=/usr/local/bin/$runner $script $*" >>/etc/postfix/master.cf

postconf -e 'transport_maps=lmdb:/etc/postfix/transport'

echo "$user@$DESTINATION $user:" >>/etc/postfix/transport
postmap /etc/postfix/transport
postfix reload
