create or replace function auth.fn_jwt_time
    ( in_timestamp timestamp with time zone
    )
returns bigint
language sql
as $$
  select extract(epoch from in_timestamp)::bigint;
$$;
