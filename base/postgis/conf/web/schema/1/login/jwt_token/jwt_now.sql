create or replace function web.jwt_now()
returns bigint
language sql
as $$
  select extract(epoch from now())::bigint;
$$;
