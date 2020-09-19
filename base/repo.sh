#!/bin/bash

image="$1"

# sed:
# -n: silent; do not print the whole (modified) file
# 's~regex~\groupno~p':
#   p: do print what's found
echo "$image" | sed -n 's~.*/\([^:]\+\).*~\1~p'
