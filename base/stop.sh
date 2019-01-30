#!/bin/bash

CONTAINER="$1"

echo "Stopping $CONTAINER..."

set +e
sudo docker stop "$CONTAINER" 2>/dev/null
set -e
