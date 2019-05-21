#!/bin/bash
basedir=$(dirname "${1}")

echo '' | "${basedir}/run/run.sh" "${2:-latest}"
