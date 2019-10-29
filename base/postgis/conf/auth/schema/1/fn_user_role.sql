-- With the table in place we can make a helper to check a password against the
-- encrypted column. It returns the database role for a user if the email and
-- password are correct.

create or replace function
auth.fn_user_role(email text, pass text) returns name
  language plpgsql
  as $$
begin
  return (
  select role from auth.tbl_users
   where tbl_users.email = fn_user_role.email
     and tbl_users.pass = crypt(fn_user_role.pass, tbl_users.pass)
  );
end;
$$;

-- login should be on your exposed schema
-- create or replace function
-- schema.fn_login(email text, pass text) returns auth.jwt_token as $$
-- declare
--   _role name;
--   result auth.jwt_token;
-- begin
--   -- check email and password
--   select auth.fn_user_role(email, pass) into _role;
--   if _role is null then
--     raise invalid_password using message = 'invalid user or password';
--   end if
--   ;
--   select sign(
--       row_to_json(r), current_setting('app.jwt_secret')
--     ) as token
--     from (
--       select _role as role, fn_login.email as email,
--          extract(epoch from now())::integer + 60*60 as exp
--     ) r
--     into result;
--   return result;
-- end;
-- $$ language plpgsql security definer;
