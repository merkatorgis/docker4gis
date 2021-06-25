#!/bin/sh

[ -f ~/.configured ] && exit

conf() {
    echo "$1 = '$2'" >>"$CONFIG_FILE"
}

dev() {
    [ "$DOCKER_ENV" = DEVELOPMENT ] || [ "$DOCKER_ENV" = DEV ]
}

# https://www.pgadmin.org/docs/pgadmin4/latest/debugger.html
dev && conf shared_preload_libraries plugin_debugger

log_statement=ddl
dev && log_statement=all
conf log_statement "$log_statement"

# Now that the conf is written, get out of the way of any future starts.
touch ~/.configured
