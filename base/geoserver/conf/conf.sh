#!/bin/bash

SCRIPT="$1"

if [ "$SCRIPT" ]; then
	DIR="$PWD"
	cd $(dirname "$SCRIPT")
	"$SCRIPT"
	cd "$DIR"
else
	cp -r /tmp/conf/certificates/ /
	find $(dirname "$0") -name 'conf.sh' -mindepth 2 -exec "$0" {} \;
fi
