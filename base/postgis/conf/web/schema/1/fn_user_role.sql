-- With the table in place we can make a helper to check a password against the
-- encrypted column. It returns the database role for a user if the email and
-- password are correct.

create or replace function web.fn_user_role
    ( in_email text
    , in_pass  text
)
returns name
language plpgsql
as $$
declare
    c_role name := role from web.tbl_user
        where email = in_email
        and pass = crypt(in_pass, pass)
    ;
begin
    -- Fast logins are insecure
    perform pg_sleep(1)
    ;
    if c_role is null
    then
        raise invalid_password
        using message = 'invalid user or password';
    else
        return c_role;
    end if;
end;
$$;
