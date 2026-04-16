#!/bin/bash
set -e

pushd schema/"$(basename "$0" .sh)"

# select current_setting('app.jwt_secret');
# needs at least 32 characters
PGRST_JWT_SECRET=$(pg.sh -Atc 'select gen_random_uuid()::text || gen_random_uuid()::text')
pg.sh -c "alter database ${PGDATABASE} set app.jwt_secret to '${PGRST_JWT_SECRET}'"

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
