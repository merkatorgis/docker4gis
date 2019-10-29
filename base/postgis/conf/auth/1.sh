#!/bin/bash

pushd schema/1

# current_setting('app.jwt_secret')
# needs at least 32 characters
jwt_secret="$(pg.sh -c 'select gen_random_uuid()' -At).$(pg.sh -c 'select gen_random_uuid()' -At)"
pg.sh -c "ALTER DATABASE ${POSTGRES_DB} SET app.jwt_secret TO '${jwt_secret}'"

pg.sh -f jwt_token.sql
pg.sh -f tbl_users.sql

popd
