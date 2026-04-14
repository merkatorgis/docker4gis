#!/bin/sh

set -x

# E.g. Europe/Amsterdam.
TZ=${TZ:-Etc/UTC}

# E.g. Europe.
geographic_area=${TZ%/*}
# E.g. Amsterdam.
region_city=${TZ#*/}

if which apk; then
    apk add --no-cache tzdata
    cp /usr/share/zoneinfo/"$TZ" /etc/localtime
fi

if which apt; then
    apt update
    apt install -y tzdata
fi

if which dpkg-reconfigure; then
    (
        echo "$geographic_area"
        echo "$region_city"
    ) | dpkg-reconfigure tzdata
fi
