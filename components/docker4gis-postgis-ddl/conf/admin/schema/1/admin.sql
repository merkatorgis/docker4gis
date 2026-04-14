create or replace function "admin"."dump"
	( 
	)
returns text
language plsh
as $$
#!/bin/bash
dump
$$;

create or replace function "admin"."dump_schema"
	( "schema" text
	)
returns text
language plsh
as $$
#!/bin/bash
dump_schema -n "$1"
$$;

create or replace function "admin"."restore_schema"
	( "schema" text
	)
returns text
language plsh
as $$
#!/bin/bash
restore_schema -n "$1"
$$;
