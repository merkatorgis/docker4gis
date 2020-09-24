#!/bin/bash

login="${1}"
comment="${2}"

adduser -D "${login}"
usermod -c "${comment}" "${login}"
