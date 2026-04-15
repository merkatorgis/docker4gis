create or replace function new_user
    ( email citext
    , admin boolean default false
    )
returns void
language sql
security definer
as $$
    select web.new_user(email, admin);
$$;

grant execute on function new_user
    ( citext
    , boolean
    )
to web_admin
;

comment on function new_user is
$$Create a new user account.
Use change_password to verify the email address.
$$;
