#!/bin/bash
set -e

scripts_dir="$1"
schema_name="${2:-$(basename ${scripts_dir})}"

current=0

update()
{
	mysql.sh "${schema_name}" -e "
		DROP FUNCTION IF EXISTS __version;
		DELIMITER $$
		CREATE FUNCTION __version() RETURNS int DETERMINISTIC
		BEGIN
			RETURN ${current};
		END$$
	" >/dev/null
}

query()
{
	echo $(mysql.sh "${schema_name}" -sNe "SELECT __version()" 2>/dev/null)
}

next()
{
	echo $(( ${current} + 1 ))
}

if current=$(query); then true; fi

pushd "${scripts_dir}" >/dev/null

if [ -f 0.sh ]; then
	./0.sh
fi

while [ -f $(next).sh ]; do
	current=$(next)
	"./${current}.sh"
	update
done 

popd >/dev/null
