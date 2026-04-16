-- See https://docs.geoserver.org/main/en/user/data/database/sqlsession.html.

-- Example Session startup SQL:
-- select wms.envelope('${envelope}')
-- , wms.env('access_token', '${access_token}')

drop function if exists wms.env(text, text)
;
create or replace function wms.env
  ( p_key text
  , p_value text
  )
returns void
language sql
immutable
as $function$
  select set_config
      ( 'wms.' || lower(p_key)
      , p_value
      , false
      )
$function$;

grant execute on function wms.env(text, text)
to public
;

comment on function wms.env(text, text) is
$$Set a WMS environment variable.
$$;


drop function if exists wms.envelope(text)
;
create or replace function wms.envelope
  ( p_envelope text
  )
returns void
language sql
immutable
as $function$
  select wms.env
    ( 'envelope'
    , coalesce
      ( nullif
        ( p_envelope
        , ''
        )
      , '-180,-90,180,90,4326'
      )
    )
$function$;

grant execute on function wms.envelope(text)
to public
;

comment on function wms.envelope(text) is
$$Set the WMS envelope.
$$;


drop function if exists wms.env(text)
;
create or replace function wms.env
  ( p_key text
  )
returns text
language sql
stable
as $function$
  select current_setting
      ( 'wms.' || lower(p_key)
      );
$function$;

grant execute on function wms.env(text)
to public
;

comment on function wms.env(text) is
$$Get a WMS environment variable.
$$;


drop function if exists wms.env(text, jsonb)
;
create or replace function wms.env
  ( p_key text
  , p_query jsonb
  )
returns text
language plpgsql
immutable
as $function$
declare
    c_escapedSemicolon text := '||EscapedSemicolon||';
    c_escapedColon text := '||EscapedColon||';
    v_env text := web_get_query(p_query, 'env');
    v_kvp text;
    v_parts text[];
    v_key text;
begin
    v_env := replace(v_env, '\;', c_escapedSemicolon);
    foreach v_kvp in array string_to_array(v_env, ';')
    loop
        v_kvp := replace(v_kvp, c_escapedSemicolon, ';');
        v_kvp := replace(v_kvp, '\:', c_escapedColon);
        v_parts := string_to_array(v_kvp, ':');
        v_key := replace(v_parts[1], c_escapedColon, ':');
        if v_key ilike p_key then
          -- Found it.
            return replace(v_parts[2], c_escapedColon, ':');
        end if;
    end loop;
    -- Not found it.
    return null;
end $function$;

grant execute on function wms.env(text, jsonb)
to public
;

comment on function wms.env(text, jsonb) is
$$Get a WMS environment variable from a Query object.
$$;


drop function if exists wms.envelope(integer, jsonb)
;
create or replace function wms.envelope
  ( p_srid integer
  , p_query jsonb
  )
returns geometry
language sql
immutable
as $function$
  select wms.envelope
      ( p_srid
      , wms.env('envelope', p_query)
      );
$function$;

grant execute on function wms.envelope(integer, jsonb)
to public
;

comment on function wms.envelope(integer, jsonb) is
$$Get the WMS envelope from a Query object.
$$;
