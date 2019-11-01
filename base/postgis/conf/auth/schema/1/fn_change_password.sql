create or replace function auth.fn_change_password
    ( in_email text
    , in_url text
    , in_subject text default 'Create password'
    , in_template text default 'Please follow this link to create your password: %s'
    )
returns void
language plpgsql
as $$
declare
begin
    update auth.tbl_users
        set pass = null
        , reauth = true
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
                , (select * from auth.fn_jwt_token
                    ( 'save_password' -- role
                    , 60 * 15 -- expire in 15 minutes
                    , format('{email, %s}', in_email)::text[] -- extra claim
                    ))

                )
            )
        );
end;
$$;
