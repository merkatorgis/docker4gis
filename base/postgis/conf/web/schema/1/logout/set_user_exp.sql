create or replace function web.set_user_exp
    ( role name
    )
returns void
language sql
security definer
as $$
    update web.users
    set exp = web.jwt_now() - 1 -- -1 to ensure before iat new token
    where users.role = set_user_exp.role
    ;
$$;
