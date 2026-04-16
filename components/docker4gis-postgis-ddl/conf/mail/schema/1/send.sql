create or replace function mail.send
	( "to"      text
	, "subject" text
	, "message" text
	)
returns text
language plsh
as $$
#!/bin/sh
to="$1"; subject="$2"; message="$3"
echo "${message}" | mail.sh "${to}" "${subject}"
$$;
