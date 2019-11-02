create or replace function web.fn_jwt_token
    ( in_role    name
    , in_seconds bigint
    , in_claims  text[] default '{}'
    )
returns web.jwt_token
language plpgsql
as $$
declare
  result web.jwt_token;
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
                , web.fn_jwt_time(now()) + in_seconds as exp
            ) r
          )
        , current_setting('app.jwt_secret')
        ) as token
    into result;
    return result;
end;
$$;

-- eg: select * from web.fn_jwt_token('user2', 60 * 60, '{extra1, bla, extra2, 64}');
