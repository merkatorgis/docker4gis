create or replace function mail.fn_send
  ( in_from text
	, in_to text
	, in_subject text
	, in_message text
	)
returns text
language plsh
as $$
#!/bin/sh
from="$1"; to="$2"; subject="$3"; message="$4"
echo "${message}" | mail.sh "${from}" "${to}" "${subject}"
$$;
