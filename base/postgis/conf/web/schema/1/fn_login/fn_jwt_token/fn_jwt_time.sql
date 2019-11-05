create or replace function web.fn_jwt_now()
returns bigint
language sql
as $$
  select extract(epoch from now())::bigint;
$$;
