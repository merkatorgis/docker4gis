#!/bin/bash

main_script="$1"
tag="${2:-latest}"

basedir=$(dirname "${main_script}")
echo '' | "${basedir}/.package/run.sh" "${tag}"
