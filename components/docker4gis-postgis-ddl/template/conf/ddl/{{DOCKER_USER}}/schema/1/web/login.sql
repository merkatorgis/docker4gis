create or replace function login
    ( email    citext
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
    ( citext
    , text
    )
to web_anon
;

comment on function login is
$$Verify credentials to return a token gaining access to your privileges.
Pass in the token with any following requests using the Authorization header;
the header's value should be: 'Bearer ${token}'
$$;
