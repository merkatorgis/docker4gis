create or replace function public.get_user_exp
    ( in_role name
    )
returns bigint
language sql
security definer
as $$
    select exp from web.user
    where role = in_role
    ;
$$;

grant execute on function public.get_user_exp
    ( name
    )
to public
;
