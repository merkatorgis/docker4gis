create or replace function fn_login
    ( in_email    text
    , in_password text
    )
returns web.jwt_token
language sql
security definer
as $$
    select web.fn_login
        ( in_email
        , in_password
        , null -- never expire
        -- , '{extra_claim1, value1, extra_claim2, value2}'
        );
$$;

grant execute on function fn_login
    ( text
    , text
    )
to web_anon
;
