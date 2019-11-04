create or replace function public.fn_logout()
returns void
language sql
as $$
    select public.fn_set_user_exp(current_user)
    ;
$$;

grant execute on function public.fn_logout()
to web_user
;
