#!/bin/bash
set -e

schema()
{
    pg.sh -c "set schema '${SCHEMA}'" "$@"
}

schema -f fn_new_user.sql
schema -f fn_change_password.sql
schema -f fn_login.sql
schema -f fn_save_password.sql
schema -f fn_logout.sql
