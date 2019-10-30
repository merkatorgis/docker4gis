#!/bin/bash
set -e

scripts_dir="$1"
schema_name="${2:-$(basename ${scripts_dir})}"

if [ $(pg.sh -Atc "
		select count(*)
		from information_schema.routines
		where routine_name = '__version'
		and routine_schema = '${schema_name}'
	 ") = 0 ]
then
	current=0
	pg.sh -c "create schema if not exists ${schema_name}"
	if [ "${schema_name}" != mail -a "${schema_name}" != auth ]
	then
		pg.sh -c "grant usage on schema ${schema_name} to web_anon"
	fi
else
	current=$(pg.sh -Atc "select ${schema_name}.__version()")
fi

update()
{
	pg.sh -c "
		CREATE OR REPLACE FUNCTION ${schema_name}.__version()
		RETURNS integer
		LANGUAGE plpgsql
		AS \$\$
		BEGIN
		    RETURN ${current};
		END;
		\$\$;
	"
	if [ ${current} = 1 ]
	then
		pg.sh -c "
			COMMENT ON FUNCTION ${schema_name}.__version() IS \$\$
				Retourneert het versienummer van het datamodel in dit schema,
				zodat de migratiescripts weten waar ze moeten beginnen.
			\$\$;
		"
	fi
}

next()
{
	echo $(( ${current} + 1 ))
}

pushd "${scripts_dir}"

if [ -f 0.sh ]
then
	./0.sh
fi

while [ -f $(next).sh ]
do
	current=$(next)
	"./${current}.sh"
	update
done 

popd
