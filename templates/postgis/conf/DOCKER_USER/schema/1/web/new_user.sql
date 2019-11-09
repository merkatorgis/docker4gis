create or replace function new_user
    ( email text
    , admin boolean default false
    )
returns void
language plpgsql
security definer
as $body$
declare
    -- web.new_user returns the new usr's role name
    role name := web.new_user(email, admin);
begin
    execute format
        ( $$
            create policy thing_%s on things to %s
            using (web_user = '%s')
            with check (web_user = '%s')
          $$
        , role, role, role, role
        );
end;
$body$;

grant execute on function new_user
    ( text
    , boolean
    )
to web_admin
;
