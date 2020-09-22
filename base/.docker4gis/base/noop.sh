#!/bin/bash

name="$1"
value="$2"

if [ "$value" ]; then
	echo "$name"="$value"
else
	echo noop=noop
fi
