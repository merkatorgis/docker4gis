#!/bin/bash

USER="$1"
SCRIPT="$2"

addmailbox.sh "$USER"

LOGDIR="/util/runner/log/$(dirname $SCRIPT)"
mkdir -p "$LOGDIR"
chown "$USER" "$LOGDIR"

echo "$USER   unix  -       n       n       -       -       pipe
      user=$USER argv=/util/runner.sh $SCRIPT" >> /etc/postfix/master.cf

postconf -e 'transport_maps=hash:/etc/postfix/transport'

if postfix status; then
	# Run time, $DESTINATION known
	echo "${USER}@${DESTINATION} ${USER}:" >> /etc/postfix/transport
	postmap /etc/postfix/transport
	postfix reload
else
	# Build time, $DESTINATION prone to change
	echo "${USER}@{{DESTINATION}} ${USER}:" >> /etc/postfix/transport.template
fi
