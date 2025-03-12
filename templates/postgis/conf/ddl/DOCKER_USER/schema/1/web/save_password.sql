create or replace function save_password
    ( email    citext
    , password text
    )
returns web.jwt_token
language sql
security definer
as $$
    -- web.save_password throws user not found exception
    select web.save_password(email, password)
    ;
    select login(email, password)
    ;
$$;

grant execute on function save_password
    ( citext
    , text
    )
to web_passwd
;

comment on function save_password is
$$Store a new password using the token emailed by change_password.
Any tokens existing for this user get invalidated.
$$;
