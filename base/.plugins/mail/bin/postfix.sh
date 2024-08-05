#!/bin/bash
set -x

POSTFIX_DOMAIN=${POSTFIX_DOMAIN:-$HOSTNAME}

myhostname=$POSTFIX_DOMAIN
postconf -e myhostname="$myhostname"

# configure the mail client to use the domain after the @ the from address
# see: https://unix.stackexchange.com/a/603373, https://askubuntu.com/a/1083644
echo "address {
  email-domain $POSTFIX_DOMAIN;
};
" >/etc/mailutils.conf

# turning off chroot operation: replace y with n
# see: http://www.postfix.org/DEBUG_README.html#logging
sed -i 's/\(^\w\+\s\+\w\+\s\+\S\s\+\S\s\+\)y\b/\1n/g' /etc/postfix/master.cf

set +x

while true; do
    echo -n "$PPID $(date -Ins) "
    if ! postfix status; then
        echo "$PPID $(date -Ins) start $myhostname $(
            postfix start
        )"
    fi
    sleep 5
done &
