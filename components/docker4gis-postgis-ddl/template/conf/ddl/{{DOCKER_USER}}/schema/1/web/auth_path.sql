DROP FUNCTION IF EXISTS auth_path
;
CREATE OR REPLACE FUNCTION auth_path
    ( "Method" text
    , "Path" text
    , "Query" jsonb
    , "Body" text
    )
RETURNS void
LANGUAGE plpgsql
STABLE
AS $function$
declare
    "ok" bool := false;
begin
--     raise log $log$
-- Method=%
-- Path=%
-- Query=%
-- Body=%$log$, "Method", "Path", "Query", "Body";

    -- Set the "ok" variable to true if all checks pass.
    if 1 = 1 then
        ok := true;
    end if;

    if not "ok" then
        raise insufficient_privilege;
    end if;
end $function$
;

grant "execute" on function "auth_path"
to "web_user"
, "web_anon"
;

comment on function "auth_path" is
$$This function is the endpoint for the default value of the AUTH_PATH variable
(http://$DOCKER_USER-api:8080/rpc/auth_path) in the Proxy component, whith
PostgREST as the API component.
$$;
