create or replace function web.save_password
    ( email    text
    , password text
    )
returns void
language plpgsql
as $$
declare
begin
    update web.users
        set pass = crypt(password, gen_salt('bf'))
        , exp = web.jwt_now() - 1 -- -1 to ensure before iat new token
        where users.email = save_password.email
        and   users.email = current_setting('request.jwt.claim.email')
    ;
    if not found
    then
        raise exception 'user not found';
    end if
    ;
end;
$$;
