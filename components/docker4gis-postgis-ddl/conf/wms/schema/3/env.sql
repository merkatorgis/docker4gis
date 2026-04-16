CREATE OR REPLACE FUNCTION wms.env(p_key text, p_query jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
declare
    c_escapedSemicolon text := '||EscapedSemicolon||';
    c_escapedColon text := '||EscapedColon||';
    v_env text := web_get_query(p_query, 'env');
    v_kvp text;
    v_parts text[];
    v_key text;
begin
    if v_env is null then
        return null;
    end if;
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
end $function$
;
