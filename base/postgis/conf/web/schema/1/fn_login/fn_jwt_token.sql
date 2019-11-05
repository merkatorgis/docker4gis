create or replace function web.fn_jwt_token
    ( in_role    name
    , in_seconds bigint default 0
    , in_claims  text[] default '{}'
    )
returns web.jwt_token
language plpgsql
as $$
declare
    token jsonb := row_to_json(r)::jsonb
        from (
            select in_role as role
            , web.fn_jwt_now() as iat
            , web.fn_jwt_now() + in_seconds as exp
        ) r;
    result web.jwt_token;
begin
    if in_seconds is null
    then
        token := token - 'exp';
    end if
    ;
    select sign
        ( (token || jsonb_object(in_claims))::json
        , current_setting('app.jwt_secret')
        ) as token
    into result
    ;
    return result;
end;
$$;

-- eg: select * from web.fn_jwt_token('user2', 60 * 60, '{extra1, bla, extra2, 64}');
