#!/bin/sh

set -x

if which apk; then
    apk update
    apk add --no-cache \
        coreutils bash
fi

here=$(dirname "$0")

mv "$here"/runner.sh /usr/local/bin
