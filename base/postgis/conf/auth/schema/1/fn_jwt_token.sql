create or replace function auth.fn_jwt_token
    ( in_role name
    , in_seconds bigint
    , in_claims text[] default '{}'
    )
returns auth.jwt_token
language plpgsql
as $$
declare
  result auth.jwt_token;
begin
    select sign
        ( (jsonb_object
            ( array
                [ 'role', in_role
                , 'exp', (auth.fn_jwt_time(now()) + in_seconds)::text
                ]
            ) ||
           jsonb_object
            ( in_claims
            )
          )::json
        , current_setting('app.jwt_secret')
        ) as token
    into result;
    return result;
end;
$$;

-- eg: select * from auth.fn_jwt_token('user2', 60 * 60, '{extra1, bla, extra2, 64}');
