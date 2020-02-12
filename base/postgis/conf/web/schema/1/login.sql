create or replace function web.login
    ( email    citext
    , password text
    , seconds  bigint default 0
    , claims   text[] default '{}'
    )
returns web.jwt_token
language sql
as $$
-- web.user_role checks email and password, returns role,
-- and throws invalid_password exception
select web.jwt_token
    ( (select web.user_role
        ( email
        , password
        ))
    , seconds
    , claims
    );
$$;
