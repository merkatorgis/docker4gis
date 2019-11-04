create or replace function web.fn_logout
    ( in_role name
    )
returns void
language sql
as $$
    select web.fn_set_user_exp(in_role)
    ;
$$;
