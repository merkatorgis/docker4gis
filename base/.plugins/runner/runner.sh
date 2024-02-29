#!/bin/bash

# set -x

# In some cases, we're run from an "empty" environment. In that case, a
# workaround to get the DOCKER_USER value is to run a thus-named copy of this
# script.
DOCKER_USER=${DOCKER_USER:-$(basename "$0")}

which "$1" >/dev/null || {
    echo "No executable command: $1"
    exit 127
}
script=$(which "$1")
shift 1

log="/util/runner/log/$DOCKER_USER/$(whoami)$script.$(date -I).log"
mkdir -p "$(dirname "$log")"

echo "$$ > $(date -Ins)" >>"$log"
"$script" "$$" "$@" >>"$log" 2>&1
err=$?

echo "$$ < $(date -Ins)" >>"$log"
exit "$err"
