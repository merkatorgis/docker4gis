create or replace function public.get_user_exp
    ( role name
    )
returns bigint
language sql
security definer
as $$
    select exp
    from web.users
    where users.role = get_user_exp.role
    ;
$$;

grant execute on function public.get_user_exp
    ( name
    )
to public
;
