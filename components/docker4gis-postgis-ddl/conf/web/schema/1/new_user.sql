create sequence web.web_user_seq
;

create or replace function web.new_user
    ( email citext
    , admin boolean default false
    )
returns name
language plpgsql
as $$
declare
    role text := 'web_user' || nextval('web.web_user_seq');
begin
    execute format('create role %s nologin', role)
    ;
    execute format('grant %s to web_authenticator', role)
    ;
    if admin
    then
        execute format('grant web_admin to %s', role);
    else
        execute format('grant web_user to %s', role);
    end if
    ;
    insert into web.users
        ( email
        , role
        )
    values
        ( email
        , role
        );
	return role;
end;
$$;
