drop function if exists public.web_get_header
;
create or replace function public.web_get_header
    ( p_header jsonb
    , p_key text
    )
returns text
language sql
immutable
as $function$
    -- "value" is an array of strings; we extract the first element.
    SELECT "value"->>0
    -- "jsonb_each" returns a set of key-value pairs. This method allows us to
    -- select the key case-insensitively.
    FROM jsonb_each("p_header")
    WHERE "key" ilike "p_key"
$function$
;

grant execute on function public.web_get_header
to public
;

comment on function public.web_get_header is
$$Reads the (first) value of the given key in the given Header object.
$$;


drop function if exists public.web_get_query
;
create or replace function public.web_get_query
    ( p_query jsonb
    , p_key text
    )
returns text
language sql
immutable
as $function$
    -- Query has the same object structure as Header.
    select public.web_get_header
        ( p_query
        , p_key
        )
$function$
;

grant execute on function public.web_get_query
to public
;

comment on function public.web_get_query is
$$Reads the (first) value of the given key in the given Query object.
$$;


drop function if exists public.web_if_modified_since
;
create or replace function public.web_if_modified_since
    ( p_header jsonb
    )
returns timestamptz
language sql
immutable
as $function$
    select to_timestamp
        ( public.web_get_header
            ( p_header
            , 'if-modified-since'
            )
        , 'Dy, DD Mon YYYY HH24:MI:SS TZ'
        )
$function$
;

grant execute on function public.web_if_modified_since
to public
;

comment on function public.web_if_modified_since is
$$Converts the value of the If-Modified-Since header, e.g.
'Wed, 19 Feb 2025 16:40:16 GMT', to a timestamp.
$$;


drop function if exists public.web_last_modified
;
create or replace function public.web_last_modified
    ( p_value timestamptz
    )
returns jsonb
language plpgsql
immutable
as $function$
declare
    v_last_modified text := to_char
        ( p_value AT TIME ZONE 'GMT'
        , 'Dy, DD Mon YYYY HH24:MI:SS'
        ) || ' GMT';
begin
    if v_last_modified is null then
        return null::jsonb;
    else
        return jsonb_build_object
            ( 'Last-Modified', array[v_last_modified]
            );
    end if;
end $function$
;

grant execute on function public.web_last_modified
to public
;

comment on function public.web_last_modified is
$$Converts a timestamp to a string in the format of the Last-Modified header,
e.g. 'Wed, 19 Feb 2025 16:40:16 GMT'.
$$;


drop function if exists public.web_cache_path_result
;
create or replace function public.web_cache_path_result
    ( p_header jsonb default null::jsonb
    , p_last_modified timestamptz default null::timestamptz
    , p_max_age integer default 0
    )
returns jsonb
language plpgsql
immutable
as $function$
declare
    v_if_modified_since timestamptz := public.web_if_modified_since("p_header");
    v_stale boolean := true;
    v_header jsonb;
    v_max_age text := 'no-cache';
begin
    -- Truncate to seconds to prevent false differences in the comparison with
    -- v_if_modified_since.
    p_last_modified := date_trunc
        ( 'second'
        , coalesce
            ( p_last_modified
            , '1900-01-01'::timestamptz
            )
        );

    -- Set v_stale to false if not stale.
    if v_if_modified_since is not null then
        v_stale := p_last_modified > v_if_modified_since;
    end if;

    -- Format the max-age part of the Cache-Control header.
    if p_max_age > 0 then
        v_max_age := 'max-age=' || p_max_age;
    end if;

    -- Enable calling web_cache_path_result() without parameters to render a
    -- "stale" result with no header.
    if p_header is not null then
        -- Render a possibly non-stale result with the proper header values.
        v_header := public.web_last_modified
            ( p_last_modified
            ) ||
            jsonb_build_object
                ( 'Cache-Control'
                , array[format('private, %s, immutable', v_max_age)]
                );
    end if;

    return jsonb_build_object
        ( 'Stale', v_stale
        , 'Header', v_header
        );
end $function$
;

grant execute on function public.web_cache_path_result
to public
;

comment on function public.web_cache_path_result is
$$Construct a result object for the cache_path function, based on the
If-Modified-Since header and the last_modified timestamp.
$$;
