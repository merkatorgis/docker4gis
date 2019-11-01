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
        ( (select
            (
                row_to_json(r)::jsonb
                || jsonb_object
                    ( in_claims
                    )
            )::json
            from (
                select in_role as role
                , auth.fn_jwt_time(now()) + in_seconds as exp
            ) r
          )
        , current_setting('app.jwt_secret')
        ) as token
    into result;
    return result;
end;
$$;

-- eg: select * from auth.fn_jwt_token('user2', 60 * 60, '{extra1, bla, extra2, 64}');
