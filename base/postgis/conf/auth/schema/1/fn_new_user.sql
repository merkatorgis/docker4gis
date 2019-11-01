create sequence auth.role_user_seq
;

create or replace function auth.fn_new_user
    ( in_email text
    , in_administrator boolean default false
    )
returns name
language plpgsql
as $$
declare
    c_role text := 'user' || nextval('auth.role_user_seq');
begin
    execute format('create role %s nologin', c_role)
    ;
    execute format('grant %s to authenticator', c_role)
    ;
    if in_administrator
    then
        execute format('grant administrators to %s', c_role);
    else
        execute format('grant users to %s', c_role);
    end if
    ;
    insert into auth.tbl_users
        ( email
        , role
        )
    values
        ( in_email
        , c_role
        );
	return c_role;
end;
$$;
