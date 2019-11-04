create or replace function web.fn_pre_request()
returns void
language plpgsql
as $$
declare
    claim_iat text :=
        current_setting('request.jwt.claim.iat', true)
    ;
    user_exp timestamp with time zone :=
        exp from web.tbl_user
    ;
begin
    if claim_iat <> '""' and to_timestamp(claim_iat::int) < user_exp
    then
        raise invalid_authorization_specification
        using message = 'please reauthenticate';
    end if;
end;
$$;

grant execute on function web.fn_pre_request()
    to web_anon
    , web_passwd
    , web_user
;
