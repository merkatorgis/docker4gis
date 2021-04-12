#!/bin/bash

database=${1:-$POSTGRES_DB}

dir=/fileport/$DOCKER_USER
mkdir -p "$dir"

# save roles (which aren't included in pg_dump's backup file)
pg_dumpall -U "$POSTGRES_USER" --roles-only >"$dir/$database.roles"

# backup database
pg_dump -U "$POSTGRES_USER" -Fc -b -v -f "$dir/$database.backup" "$database"
