#!/bin/bash

schema.sh "$(dirname "$0")"

dir=/fileport/$PGDATABASE
mkdir -p "$dir"
[ -n "$(getent group postgres)" ] && chown :postgres -R "$dir"
chmod g+w -R "$dir"
