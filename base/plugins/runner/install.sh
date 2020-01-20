#!/bin/sh

apk update; apk add --no-cache \
    coreutils bash

HERE=$(dirname "$0")
mkdir -p "/util/runner/log/${DOCKER_USER}"

# FIXME: dit moet op run time draaien in plaats van op build time...
chmod -R a+w "/util/runner/log/${DOCKER_USER}"

mv "$HERE/runner.sh" /usr/local/bin
rm -rf "$HERE"
