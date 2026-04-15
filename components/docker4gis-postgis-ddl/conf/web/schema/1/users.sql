create table web.users
    ( email citext primary key check ( email ~* '^.+@.+\..+$' )
    , role  name not null unique check ( length(role) < 512 )
    , pass  text default null check ( length(pass) < 512 )
    , exp   bigint default null
    );

-- We would like the role to be a foreign key to actual database roles, however
-- PostgreSQL does not support these constraints against the pg_roles table.
-- We’ll use a trigger to manually enforce it.

create or replace function web.check_users_role_exists()
returns trigger
language plpgsql
as $$
begin
    if not exists (select from pg_roles as r where r.rolname = new.role)
    then
        raise foreign_key_violation using message =
        'unknown database role: ' || new.role;
    end if
    ;
    return new;
end;
$$;

create constraint trigger check_users_role_exists
after insert or update on web.users
for each row
execute procedure web.check_users_role_exists()
;
