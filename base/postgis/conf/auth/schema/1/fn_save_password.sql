create or replace function auth.fn_save_password
    ( in_email text
    , in_password text
    )
returns void
language plpgsql
as $$
declare
begin
    update auth.tbl_users
    set pass = crypt(in_password, gen_salt('bf'))
    , reauth = false
    where email = in_email
    ;
    if not found
    then
        raise exception 'User not found';
    end if
    ;
end;
$$;
