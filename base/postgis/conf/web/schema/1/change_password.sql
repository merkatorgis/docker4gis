create or replace function web.change_password
    ( email    text
    , url      text default '${PROXY}/app'
    , subject  text default 'Create password'
    , template text default 'Within the next 15 minutes, please follow this link to create your password: %s'
    )
returns void
language plpgsql
as $$
declare
begin
    if not exists
        (select from web.users
        where users.email = change_password.email)
    then
        return;
    end if
    ;
    perform mail.fn_send
        ( change_password.email
        , change_password.subject
        , format
            ( change_password.template
            , format
                ( '%s?changepassword&token=%s'
                , change_password.url
                , (select * from web.jwt_token
                    ( 'web_passwd' -- role
                    , 60 * 15 -- expire in 15 minutes
                    , format('{email, %s}', change_password.email)::text[] -- extra claim
                    ))
                )
            )
        );
end;
$$;
