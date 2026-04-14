create or replace function web.set_user_exp
    ( role name
    )
returns void
language plpgsql
as $$
begin
    update web.users
    set exp = web.jwt_now() - 1 -- -1 to ensure before iat new token
    where users.role = set_user_exp.role
    ;
    if not found
    then
        raise foreign_key_violation
        using message = 'user not found';
    end if;
end;
$$;
