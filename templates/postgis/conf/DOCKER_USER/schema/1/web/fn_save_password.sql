create or replace function fn_save_password
    ( in_email   text
    , in_password text
    )
returns web.jwt_token
language sql
security definer
as $$
    -- web.fn_save_password throws user not found exception
    select web.fn_save_password(in_email, in_password)
    ;
    select fn_login(in_email, in_password)
    ;
$$;

grant execute on function fn_save_password
    ( text
    , text
    )
to web_passwd
;
