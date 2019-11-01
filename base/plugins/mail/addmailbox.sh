#!/bin/sh

login="${1}"
comment="${2}"

adduser -D "${login}"
usermod -c "${comment}" "${login}"

echo "ALL ALL=(${login}) NOPASSWD: ALL" >> /etc/sudoers
