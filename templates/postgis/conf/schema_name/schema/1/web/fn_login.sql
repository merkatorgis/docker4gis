create or replace function fn_login
    ( in_email    text
    , in_password text
    )
returns web.jwt_token
language sql
security definer
as $$
-- web.fn_user_role checks email and password, returns role,
-- and throws invalid_password exception
select web.fn_jwt_token
    ( (select web.fn_user_role
        ( in_email
        , in_password
        ))
    , null -- never expire
    );
$$;

grant execute on function fn_login
    ( text
    , text
    )
to web_anon
;
