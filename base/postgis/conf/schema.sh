#!/bin/bash
set -e

scripts_dir="$1"
schema_name="${2:-$(basename ${scripts_dir})}"

current=0

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
