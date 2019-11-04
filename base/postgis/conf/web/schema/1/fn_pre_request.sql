create or replace function public.fn_pre_request
    (  )
returns void
language plpgsql
security definer
as $$
declare
    claim_role name :=
        current_setting('request.jwt.claim.role', true)
    ;
    claim_iat timestamp with time zone := to_timestamp(
        current_setting('request.jwt.claim.iat', true)::int
    );
    user_exp timestamp with time zone := exp
        from web.tbl_user
        where role = claim_role -- current_user = postgis(!)
    ;
begin
    -- raise warning 'claim_role %; current_user %; claim_iat %; user_exp %', claim_role, current_user, claim_iat, user_exp;
    if claim_iat < user_exp
    then
        raise invalid_authorization_specification
        using message = 'please reauthenticate';
    end if;
end;
$$;

grant all on function public.fn_pre_request
    ( )
to public
;
