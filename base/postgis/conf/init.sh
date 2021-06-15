#!/bin/sh

[ -f ~/.configured ] && exit

conf() {
    echo "$1 = '$2'" >>"$CONFIG_FILE"
}

dev() {
    [ "$DOCKER_ENV" = DEVELOPMENT ] || [ "$DOCKER_ENV" = DEV ]
}

# https://github.com/eradman/pg-safeupdate
# http://postgrest.org/en/v7.0.0/admin.html?highlight=safeupdate#block-full-table-operations
shared_preload_libraries=safeupdate
# https://www.pgadmin.org/docs/pgadmin4/latest/debugger.html
dev && shared_preload_libraries="$shared_preload_libraries,plugin_debugger"
conf shared_preload_libraries "$shared_preload_libraries"

log_statement=ddl
dev && log_statement=all
conf log_statement "$log_statement"

# Now that the conf is written, get out of the way of any future starts.
touch ~/.configured
