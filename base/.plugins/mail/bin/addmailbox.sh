#!/bin/sh

login=${1}
comment=${2}

adduser --disabled-password --gecos "" "${login}"
usermod -c "${comment}" "${login}"

echo "ALL ALL=(${login}) NOPASSWD: ALL" >>/etc/sudoers
