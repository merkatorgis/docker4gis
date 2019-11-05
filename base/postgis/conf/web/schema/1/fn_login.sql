create or replace function web.fn_login
    ( in_email    text
    , in_password text
    , in_seconds  bigint default 0
    , in_claims   text[] default '{}'
    )
returns web.jwt_token
language sql
as $$
-- web.fn_user_role checks email and password, returns role,
-- and throws invalid_password exception
select web.fn_jwt_token
    ( (select web.fn_user_role
        ( in_email
        , in_password
        ))
    , in_seconds
    , in_claims
    );
$$;
