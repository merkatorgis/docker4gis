#!/bin/sh

apk update; apk add --no-cache \
    coreutils bash

HERE=$(dirname "$0")

mv "$HERE/runner.sh" /usr/local/bin
rm -rf "$HERE"
