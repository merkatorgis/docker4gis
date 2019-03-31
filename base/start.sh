#!/bin/bash

container="$1"

echo "Starting $container..."

docker container start "$container" 2>/dev/null
