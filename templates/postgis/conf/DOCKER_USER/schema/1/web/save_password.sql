create or replace function save_password
    ( email    text
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
    ( text
    , text
    )
to web_passwd
;
