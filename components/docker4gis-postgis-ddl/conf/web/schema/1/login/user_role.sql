-- With the table in place we can make a helper to check a password against the
-- encrypted column. It returns the database role for a user if the email and
-- password are correct.

create or replace function web.user_role
    ( email citext
    , pass  text
    )
returns name
language plpgsql
as $$
declare
    role name := role from web.users
        where users.email = user_role.email
        and users.pass = crypt(user_role.pass, users.pass)
    ;
begin
    -- Fast logins are insecure
    perform pg_sleep(1)
    ;
    if role is null
    then
        raise invalid_password
        using message = 'invalid user or password';
    else
        return role;
    end if;
end;
$$;
