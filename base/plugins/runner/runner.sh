#!/bin/bash

script="$1"
shift 1

log="/util/runner/log/${DOCKER_USER}/${script}.$(date -I).log"
mkdir -p $(dirname "${log}")

echo "$$ > $(date -Ins)" >> "${log}"
"${script}" "$$" "$@" >> "${log}" 2>&1
err="$?"

echo "$$ < $(date -Ins)" >> "${log}"
exit "${err}"
