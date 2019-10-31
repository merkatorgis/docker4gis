-- With the table in place we can make a helper to check a password against the
-- encrypted column. It returns the database role for a user if the email and
-- password are correct.

create or replace function auth.fn_user_role
  ( email text
  , pass text
)
returns name
language plpgsql
as $$
declare
  c_role name := role from auth.tbl_users
    where tbl_users.email = fn_user_role.email
    and tbl_users.pass = crypt(fn_user_role.pass, tbl_users.pass)
  ;
begin
  if c_role is null
  then
    raise invalid_password
    using message = 'invalid user or password'
    ;
  else
    return c_role
    ;
  end if;
end;
$$;
