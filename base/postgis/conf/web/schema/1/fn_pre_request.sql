create or replace function public.fn_pre_request
    (  )
returns void
language plpgsql
security definer
as $$
declare
begin
    if reauth from web.tbl_user where role = current_user
    then
        raise invalid_authorization_specification
        using message = 'please reauthenticate';
    end if;
end;
$$;

revoke all on function public.fn_pre_request
    ( )
from public
;

grant execute on function public.fn_pre_request
    ( )
to web_user
;
