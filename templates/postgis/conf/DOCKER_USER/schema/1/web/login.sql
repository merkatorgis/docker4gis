create or replace function login
    ( email    text
    , password text
    )
returns web.jwt_token
language sql
security definer
as $$
    select web.login
        ( email
        , password
        , null -- never expire
        -- , '{extra_claim1, value1, extra_claim2, value2}'
        );
$$;

grant execute on function login
    ( text
    , text
    )
to web_anon
;
