create or replace function change_password(email citext)
returns void
language sql
security definer
as $$
    -- web.change_password throws user not found exception
    select web.change_password
        ( email
        -- , subject  text default 'Create password'
        -- , template text default 'Within the next 15 minutes, please follow this link to create your password: %s'
        -- , url      text default current_setting('request.headers', true)::json->>'referer'
        );
$$;

grant execute on function change_password(citext)
to web_anon
, web_user
;

comment on function change_password is
$$Email a link to a form that lets you change your password.
$$;
