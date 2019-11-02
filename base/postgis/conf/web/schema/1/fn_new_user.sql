create sequence web.role_web_user_seq
;

create or replace function web.fn_new_user
    ( in_email text
    , in_admin boolean default false
    )
returns name
language plpgsql
as $$
declare
    c_role text := 'web_user' || nextval('web.role_web_user_seq');
begin
    execute format('create role %s nologin', c_role)
    ;
    execute format('grant %s to web_authenticator', c_role)
    ;
    if in_admin
    then
        execute format('grant web_admin to %s', c_role);
    else
        execute format('grant web_user to %s', c_role);
    end if
    ;
    insert into web.tbl_user
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
