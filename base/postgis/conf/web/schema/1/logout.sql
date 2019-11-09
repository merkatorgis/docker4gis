create or replace function web.logout
    ( in_role name
    )
returns void
language sql
as $$
    select web.set_user_exp(in_role)
    ;
$$;
