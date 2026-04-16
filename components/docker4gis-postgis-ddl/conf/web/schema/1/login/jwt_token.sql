create or replace function web.jwt_token
    ( role    name
    , seconds bigint default 0
    , claims  text[] default '{}'
    )
returns web.jwt_token
language plpgsql
as $$
declare
    token jsonb := row_to_json(r)::jsonb
        from (
            select role
            , web.jwt_now() as iat
            , web.jwt_now() + seconds as exp
        ) r;
    result web.jwt_token;
begin
    if seconds is null
    then
        token := token - 'exp';
    end if
    ;
    select sign
        ( (token || jsonb_object(claims))::json
        , current_setting('app.jwt_secret')
        ) as token
    into result
    ;
    return result;
end;
$$;

-- eg: select * from web.jwt_token('user2', 60 * 60, '{extra1, bla, extra2, 64}');
