#!/bin/bash

src=$1
dst=$2

mkdir -p "$src"
[ "$OS" = "Windows_NT" ] && src="/$src"
echo "$src":"$dst"
