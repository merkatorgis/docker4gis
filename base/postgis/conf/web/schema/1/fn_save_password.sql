create or replace function web.fn_save_password
    ( in_email    text
    , in_password text
    )
returns void
language plpgsql
as $$
declare
begin
    update web.tbl_user
        set pass = crypt(in_password, gen_salt('bf'))
        , reauth = false
        where email = in_email
    ;
    if not found
    then
        raise exception 'user not found';
    end if
    ;
end;
$$;
