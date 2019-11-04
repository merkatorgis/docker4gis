create or replace function web.fn_set_user_exp
    ( in_role name
    )
returns void
language sql
security definer
as $$
    update web.tbl_user
    set exp = now()
    where role = in_role
    ;
$$;
