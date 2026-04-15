-- [If anything is printed to the standard error, then the function aborts with
-- an error and the message is
-- printed.](https://github.com/petere/plsh/tree/ea58c0d6a287b0f3016032f6b1fad2ed33f1572e)

create or replace function "admin"."dump"
	( 
	)
returns text
language plsh
as $function$
#!/bin/bash
dump 2>&1
$function$;

create or replace function "admin"."dump_schema"
	( "schema" text
	)
returns text
language plsh
as $function$
#!/bin/bash
dump_schema -n "$1" 2>&1
$function$;

create or replace function "admin"."restore_schema"
	( "schema" text
	)
returns text
language plsh
as $function$
#!/bin/bash
restore_schema -n "$1" 2>&1
$function$;
