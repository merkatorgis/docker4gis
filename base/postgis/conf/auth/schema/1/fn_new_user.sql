create sequence role_user_seq
;

create or replace function auth.fn_new_user
    ( in_email text
    )
returns void
language plpgsql
as $$
declare
    c_role text := 'user' || nextval('role_user_seq');
begin
    execute format('create role %s nologin', c_role)
    ;
    execute format('grant users to %s', c_role)
    ;
    execute format('grant %s to authenticator', c_role)
    ;
    insert into auth.tbl_users
        ( email
        , role
        )
    values
        ( in_email
        , c_role
        )
    ;
end;
$$;
