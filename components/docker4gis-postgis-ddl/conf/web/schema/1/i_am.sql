create or replace function public.i_am
    ( role name
    )
returns boolean
language sql
as $$
    select pg_has_role(role, 'member');
$$;

grant execute on function public.i_am
    ( name
    )
to public
;
