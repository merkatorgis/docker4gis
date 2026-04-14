grant usage on schema wms
to public
;

drop function if exists wms.envelope(integer, text)
;
create or replace function wms.envelope
  ( p_srid integer
  , p_envelope text
  )
returns geometry
language sql
immutable
as $function$
  select ST_Transform
    ( ST_MakeEnvelope
      ( (string_to_array(p_envelope, ','))[1]::float
      , (string_to_array(p_envelope, ','))[2]::float
      , (string_to_array(p_envelope, ','))[3]::float
      , (string_to_array(p_envelope, ','))[4]::float
      , (string_to_array(p_envelope, ','))[5]::integer
      )
    , p_srid
    )
$function$;

grant execute on function wms.envelope(integer, text)
to public
;

comment on function wms.envelope(integer, text) is
$$Create a box geometry in the given SRID from an envelope string.
$$;


drop function if exists wms.envelope(integer)
;

create or replace function wms.envelope
  ( p_srid integer
  )
returns geometry
language sql
stable
as $function$
  select wms.envelope
    ( p_srid
    , current_setting
      ( 'wms.envelope'
      )
    )
$function$;

grant execute on function wms.envelope(integer)
to public
;

comment on function wms.envelope(integer) is
$$Create a box geometry in the given SRID from the 'wms.envelope' setting.
$$;