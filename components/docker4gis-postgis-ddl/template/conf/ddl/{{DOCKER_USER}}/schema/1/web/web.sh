#!/bin/bash

schema() {
    pg.sh --set ON_ERROR_STOP=on -1 \
        -c "set search_path to $SCHEMA, public" \
        "$@"
}

(
    cd "$(dirname "$0")" &&
        schema -f auth_path.sql &&
        schema -f cache_path.sql &&
        schema -f new_user.sql &&
        schema -f change_password.sql &&
        schema -f login.sql &&
        # This one can't be done like the others, since we need to call
        # $SCHEMA.login.
        pg.sh -c "
            create or replace function $SCHEMA.save_password
                ( email citext
                , password text
                )
            returns web.jwt_token
            language sql
            security definer
            as \$function\$
                -- web.save_password throws user not found exception
                select web.save_password(email, password)
                ;
                select $SCHEMA.login(email, password)
                ;
            \$function\$
        " &&
        schema -f save_password.sql &&
        schema -f logout.sql
)
