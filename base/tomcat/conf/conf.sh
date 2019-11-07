#!/bin/bash

me="$0"
conf="$1"

if [ "${conf}" ]; then
	pushd $(dirname "${conf}")
	"${conf}"
	popd
else
	find $(dirname "${me}") -name 'conf.sh' -mindepth 2 -exec "${me}" {} \;
fi
