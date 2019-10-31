create or replace function auth.fn_change_password
    ( in_email text
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
        , 'Wachtwoord aanmaken'
        , format
            ( 'Hier komt een link?token=%s naar de wachtwoord-pagina'
            , (select auth.fn_jwt_token
                ( 'change_password'
                , 60 * 15 -- 15 minutes
                ))

            )
        );
end;
$$;
