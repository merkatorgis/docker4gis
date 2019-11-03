create or replace function web.fn_logout
    ( in_role name
    )
returns void
language plpgsql
as $$
declare
begin
    update web.tbl_user
    set reauth = true
    where role = in_role
    ;
end;
$$;
