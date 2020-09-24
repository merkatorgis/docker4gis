#!/bin/bash

src="$1"
dst="$2"

mkdir -p "$src"
[ "$OS" = "Windows_NT" ] && source="/$src"
echo "$src":"$dst"
