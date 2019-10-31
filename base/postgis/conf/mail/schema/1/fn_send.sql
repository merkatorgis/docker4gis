create or replace function mail.fn_send
	( in_to text
	, in_subject text
	, in_message text
	, in_user text default ''
	)
returns text
language plsh
as $$
#!/bin/sh
to="$1"; subject="$2"; message="$3"; login="$4"
echo "${message}" | mail.sh "${to}" "${subject}" "${login}"
$$;
