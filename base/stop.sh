#!/bin/bash

CONTAINER="$1"

echo "Stopping $CONTAINER..."

set +e
docker stop "$CONTAINER" 2>/dev/null
set -e
