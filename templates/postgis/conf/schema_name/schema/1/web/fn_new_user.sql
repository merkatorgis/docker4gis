create or replace function fn_new_user
    ( in_email text
    , in_admin boolean default false
    )
returns void
language plpgsql
security definer
as $body$
declare
    c_web_user name := web.fn_new_user(in_email, in_admin);
begin
    execute format
        ( $$
            create policy pol_thing_%s on schema_name.tbl_thing to %s
            using (web_user = '%s')
            with check (web_user = '%s')
          $$
        , c_web_user, c_web_user, c_web_user, c_web_user
        );
end;
$body$;

grant execute on function fn_new_user
    ( text
    , boolean
    )
to web_admin
;
