create or replace function web.logout
    ( role name
    )
returns void
language sql
security definer
as $$
    select web.set_user_exp(role)
    ;
$$;

grant execute on function web.logout
    ( name
    )
to web_user
;
