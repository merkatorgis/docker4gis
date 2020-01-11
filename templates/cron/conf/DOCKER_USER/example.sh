#!/bin/bash
set -e

ID="$1"

echo "${ID} $(pg.sh -Atc 'select 1)"
