#!/bin/bash
# set -x

# In some cases, we're run from an "empty" environment. In that case, a
# workaround to get the DOCKER_USER value is to run a thus-named copy of this
# script.
DOCKER_USER=${DOCKER_USER:-$(basename "$0")}

script=$(realpath "$1")
shift 1

log="/util/runner/log/$DOCKER_USER/$(whoami)$script.$(date -I).log"
mkdir -p "$(dirname "$log")"

# Preserve quoted arguments with spaces; see
# https://www.gnu.org/software/bash/manual/bash.html#index-printf.
args=$(printf '%q ' "$@")
action="$script $$ $args"

echo "$$ > $(date -Ins)" >>"$log"
"$action" >>"$log" 2>&1
err="$?"

echo "$$ < $(date -Ins)" >>"$log"
exit "$err"
