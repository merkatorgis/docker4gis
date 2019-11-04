create or replace function public.fn_set_user_exp
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

grant execute on function public.fn_set_user_exp
    ( name
    )
to web_user
;
