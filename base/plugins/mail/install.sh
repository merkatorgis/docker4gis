#!/bin/bash

RELAYHOST="${1:-merkator.com}"

apk update; apk add --no-cache \
	mailx rsyslog postfix=3.2.4-r1

