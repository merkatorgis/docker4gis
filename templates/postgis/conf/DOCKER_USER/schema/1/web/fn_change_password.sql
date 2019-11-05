create or replace function fn_change_password
    ( in_email text
    )
returns void
language sql
security definer
as $$
    -- web.fn_change_password throws user not found exception
    select web.fn_change_password
        ( in_email
        )
    ;
$$;

grant execute on function fn_change_password
    ( text
    )
to web_anon
;
