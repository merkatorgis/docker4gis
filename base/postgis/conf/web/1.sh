#!/bin/bash
set -e

pushd schema/1

    # select current_setting('app.jwt_secret');
    # needs at least 32 characters
    PGRST_JWT_SECRET=$(pg.sh -Atc 'select gen_random_uuid()::text || gen_random_uuid()::text')
    pg.sh -c "alter database ${POSTGRES_DB} set app.jwt_secret to '${PGRST_JWT_SECRET}'"

    # Unlike tables/views, functions privileges work as a blacklist, so they’re
    # executable for all the roles by default. You can workaround this by revoking
    # the PUBLIC privileges of the function and then granting privileges to specific
    # roles.
    # Also to avoid doing REVOKE on every function you can enable this behavior by
    # default with:
    pg.sh -c "alter default privileges revoke execute on functions from public"

    pg.sh -f roles.sql
    pg.sh -f tbl_user.sql

    pushd fn_pre_request
        pg.sh -f fn_get_user_exp.sql
    popd
    pg.sh -f fn_pre_request.sql

    pg.sh -f fn_new_user.sql

    pushd fn_login
        pg.sh -f fn_user_role.sql
        pushd fn_jwt_token
            pg.sh -f jwt_token.sql
            pg.sh -f fn_jwt_time.sql
        popd
        pg.sh -f fn_jwt_token.sql
    popd
    pg.sh -f fn_login.sql
    pg.sh -f fn_change_password.sql
    pg.sh -f fn_save_password.sql

    pushd fn_logout
        pg.sh -f fn_set_user_exp.sql
    popd
    pg.sh -f fn_logout.sql

popd
