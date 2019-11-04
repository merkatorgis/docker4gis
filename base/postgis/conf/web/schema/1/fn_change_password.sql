create or replace function web.fn_change_password
    ( in_email    text
    , in_url      text default '${PROXY}/app'
    , in_subject  text default 'Create password'
    , in_template text default 'Within the next 15 minutes, please follow this link to create your password: %s'
    )
returns void
language plpgsql
as $$
declare
begin
    update web.tbl_user
        set pass = null
        where email = in_email
    ;
    if not found
    then
        raise exception 'user not found';
    end if
    ;
    perform mail.fn_send
        ( in_email
        , in_subject
        , format
            ( in_template
            , format
                ( '%s?changepassword&token=%s'
                , in_url
                , (select * from web.fn_jwt_token
                    ( 'web_passwd' -- role
                    , 60 * 15 -- expire in 15 minutes
                    , format('{email, %s}', in_email)::text[] -- extra claim
                    ))

                )
            )
        );
end;
$$;
