#!/bin/sh

set -x

# E.g. Europe/Amsterdam.
TZ=${TZ:-Etc/UTC}

geographic_area=${TZ%/*}
region_city=${TZ#*/}

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
