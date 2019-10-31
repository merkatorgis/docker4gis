create or replace function auth.fn_jwt_now
    ( )
returns int
language sql
as $$
  select extract(epoch from now())::int;
$$;
