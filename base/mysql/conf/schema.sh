#!/bin/bash
set -e

scripts_dir="$1"
schema_name="${2:-$(basename ${scripts_dir})}"

current=0

update()
{
	pg.sh -c "
		CREATE DEFINER=`root`@`%` FUNCTION `setCoordinator`() RETURNS int(11)
			DETERMINISTIC
		BEGIN

		RETURN 0;
		END
	" >/dev/null
}

query()
{
	echo $(pg.sh -c "SELECT ${schema_name}.__version()" --tuples-only --no-align 2>/dev/null)
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
