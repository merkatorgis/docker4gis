create table if not exists
auth.tbl_users (
  email    text primary key check ( email ~* '^.+@.+\..+$' ),
  pass     text not null check (length(pass) < 512),
  role     name not null check (length(role) < 512)
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

create constraint trigger tr_check_role_exists
  after insert or update on auth.tbl_users
  for each row
  execute procedure auth.tr_check_role_exists();

-- Next we’ll use the pgcrypto extension and a trigger to keep passwords
-- safe in the users table.

create or replace function
auth.tr_encrypt_pass() returns trigger as $$
begin
  if tg_op = 'INSERT' or new.pass <> old.pass then
    new.pass = crypt(new.pass, gen_salt('bf'));
  end if;
  return new;
end
$$ language plpgsql;

create trigger tr_encrypt_pass
  before insert or update on auth.tbl_users
  for each row
  execute procedure auth.tr_encrypt_pass();
