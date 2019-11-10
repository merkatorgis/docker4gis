create or replace function mail.fn_send
	( in_to text
	, in_subject text
	, in_message text
	)
returns text
language plsh
as $$
#!/bin/sh
to="$1"; subject="$2"; message="$3"
echo "${message}" | mail.sh "${to}" "${subject}"
$$;
