create or replace function web.save_password
    ( email    citext
    , password text
    )
returns void
language plpgsql
as $$
declare
begin
    perform web.set_user_exp((
        select role
        from web.users
        where users.email = save_password.email
        and users.email = current_setting('request.jwt.claims')::json->>'email'
    ));
    update web.users
    set pass = crypt(password, gen_salt('bf'))
    where users.email = save_password.email
    ;
end;
$$;
