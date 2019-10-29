#!/bin/bash
set -e

scripts_dir="$1"
schema_name="${2:-$(basename ${scripts_dir})}"

query()
{
	count=$(pg.sh -c "
		select count(*)
		from information_schema.routines
		where routine_name = '__version'
		and routine_schema = '${schema_name}'
	" --tuples-only --no-align)
	if [ $count = 0 ]
	then
		echo 0
	else
		echo $(pg.sh -c "SELECT ${schema_name}.__version()" --tuples-only --no-align)
	fi
}

current=$(query)

update()
{
	pg.sh -c "
		CREATE OR REPLACE FUNCTION ${schema_name}.__version() RETURNS integer AS \$\$
		BEGIN
		    RETURN ${current};
		END;
		\$\$ LANGUAGE plpgsql;
		COMMENT ON FUNCTION ${schema_name}.__version() IS \$\$
			Retourneert het versienummer van het datamodel in dit schema, zodat de migratiescripts weten waar ze moeten beginnen.
		\$\$;
	" >/dev/null
}

next()
{
	echo $(( ${current} + 1 ))
}

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
