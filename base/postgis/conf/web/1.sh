#!/bin/bash
set -e

pushd schema/"$(basename "$0" .sh)"

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

pg.sh -c "create extension if not exists citext"

pg.sh -f roles.sql
pg.sh -f users.sql

pushd pre_request
pg.sh -f get_user_exp.sql
popd
pg.sh -f pre_request.sql
pg.sh -f i_am.sql

pg.sh -f new_user.sql

pushd login
pg.sh -f user_role.sql
pushd jwt_token
pg.sh -f jwt_token.sql
pg.sh -f jwt_now.sql
popd
pg.sh -f jwt_token.sql
popd
pg.sh -f login.sql
pg.sh -f change_password.sql

pushd save_password
pg.sh -f set_user_exp.sql
popd
pg.sh -f save_password.sql
pg.sh -f logout.sql

popd
