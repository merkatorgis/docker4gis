create or replace function public.fn_get_user_exp
    ( in_role name
    )
returns timestamptz
language sql
security definer
as $$
    select exp from web.tbl_user
    where role = in_role
    ;
$$;

grant execute on function public.fn_get_user_exp
    ( name
    )
to public
;
