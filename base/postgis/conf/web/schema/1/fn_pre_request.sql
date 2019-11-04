create or replace function public.fn_pre_request()
returns void
language plpgsql
as $$
declare
    claim_iat text :=
        current_setting('request.jwt.claim.iat', true)
    ;
    user_exp timestamp with time zone :=
        public.fn_get_user_exp(current_user)
    ;
begin
    if claim_iat = '' or to_timestamp(claim_iat::int) < user_exp
    then
        raise invalid_authorization_specification
        using message = 'please reauthenticate';
    end if;
end;
$$;

grant execute on function public.fn_pre_request()
to public
;
