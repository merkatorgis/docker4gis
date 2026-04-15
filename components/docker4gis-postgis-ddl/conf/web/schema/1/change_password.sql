create or replace function web.change_password
    ( email    citext
    , subject  text default 'Create password'
    , template text default 'Within the next 15 minutes, please follow this link to create your password: %s'
    , url      text default current_setting('request.header.referer')
    )
returns void
language plpgsql
as $$
declare
begin
    select users.email
    into change_password.email
    from web.users
    where users.email = change_password.email
    ;
    if not found
    then
        raise foreign_key_violation
        using message = 'user not found';
    end if
    ;
    perform mail.send
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
                    , format
                        ( '{email, %s}'
                        , change_password.email
                        )::text[] -- extra claim
                    ))
                )
            )
        );
end;
$$;
