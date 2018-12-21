#!/bin/bash

apk update; apk add --no-cache curl curl-dev

here=$(dirname "$0")
mkdir -p /util

mv "${here}/gs.sh" "${here}/seed.sh" "${here}/truncate.sh" /util/
rm -rf "${here}"
