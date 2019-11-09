create or replace function change_password
    ( email text
    )
returns void
language sql
security definer
as $$
    -- web.change_password throws user not found exception
    select web.change_password
        ( email
        )
    ;
$$;

grant execute on function change_password
    ( text
    )
to web_anon
, web_user
;

comment on function change_password is
$$Email a link to a form that can change the password.
$$;
