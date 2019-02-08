#!/bin/bash
basedir=$(dirname "${1}")

"${basedir}/run/run.sh" "${2:-latest}"
