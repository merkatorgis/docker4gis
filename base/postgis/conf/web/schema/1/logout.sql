create or replace function web.logout
    ( role name
    )
returns void
language sql
as $$
    select web.set_user_exp(role)
    ;
$$;
