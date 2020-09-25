#!/bin/bash

name=$1
value=$2

[ "$value" ] &&
	echo "$name"="$value" ||
	echo noop=noop
