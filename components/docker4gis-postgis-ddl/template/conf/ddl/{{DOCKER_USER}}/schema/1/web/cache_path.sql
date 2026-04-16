DROP FUNCTION if exists cache_path
;
CREATE OR REPLACE FUNCTION cache_path
    ( "Path" text
    , "Query" jsonb
    , "Header" jsonb
    )
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $function$
declare
    v_last_modified timestamptz;

    -- This renders a default result without any cache-related headers.
    v_result jsonb := web_cache_path_result();

    -- Replace 'param' with something meaningful.
    v_param text := web_get_query("Query", 'param');
begin
--     raise log $log$
-- Path=%
-- Query=%
-- Header=%$log$, "Path", "Query", "Header";

    -- Note that initially, the cache_path function is declared with SECURITY
    -- DEFINER, and web_anon is granted execute on it.

    if v_param is not null then
        -- Replace now() with a value that is selected based on the Path and
        -- Query parameters (see the v_param example).
        select now() into v_last_modified
        ;
        v_result := web_cache_path_result
            ( "Header"
            , v_last_modified
            , p_max_age := 15
            );
    end if;

    -- raise log $log$Last-Modified=% Result=%$log$, v_last_modified, v_result;

    return v_result;
end $function$
;

grant execute on function cache_path
to web_user
, web_anon
;

comment on function cache_path is
$$This function is the endpoint for the default value of the CACHE_PATH variable
(http://$DOCKER_USER-api:8080/rpc/cache_path) in the Proxy component, whith
PostgREST as the API component.
$$;
