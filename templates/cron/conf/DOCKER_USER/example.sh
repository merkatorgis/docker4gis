#!/bin/bash

echo "$PPID $(pg.sh -Atc 'select 1' 2>&1)"
