create table if not exists
auth.tbl_users
  ( email  text primary key check ( email ~* '^.+@.+\..+$' )
  , role   name not null unique check ( length(role) < 512 )
  , pass   text default null check ( length(pass) < 512 )
  , reauth boolean default true
);

-- We would like the role to be a foreign key to actual database roles, however
-- PostgreSQL does not support these constraints against the pg_roles table.
-- We’ll use a trigger to manually enforce it.

create or replace function
auth.tr_check_role_exists() returns trigger as $$
begin
  if not exists (select from pg_roles as r where r.rolname = new.role) then
    raise foreign_key_violation using message =
      'unknown database role: ' || new.role;
    return null;
  end if;
  return new;
end
$$ language plpgsql;

create constraint trigger tr_check_user_role_exists
  after insert or update on auth.tbl_users
  for each row
  execute function auth.tr_check_role_exists();
