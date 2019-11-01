#!/bin/bash
set -e

scripts_dir="$1"
export SCHEMA="${2:-$(basename ${scripts_dir})}"

if [ $(pg.sh -Atc "
		select count(*)
		from information_schema.routines
		where routine_name = '__version'
		and routine_schema = '${SCHEMA}'
	 ") = 0 ]
then
	current=0
	pg.sh -c "create schema if not exists ${SCHEMA}"
	if [ "${SCHEMA}" != mail -a "${SCHEMA}" != auth ]
	then
		pg.sh -c "grant usage on schema ${SCHEMA} to web_anon"
		pg.sh -c "grant usage on schema ${SCHEMA} to save_password"
		pg.sh -c "grant usage on schema ${SCHEMA} to users"
	fi
else
	current=$(pg.sh -Atc "select ${SCHEMA}.__version()")
fi

update()
{
	pg.sh -c "
		CREATE OR REPLACE FUNCTION ${SCHEMA}.__version()
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
			COMMENT ON FUNCTION ${SCHEMA}.__version() IS \$\$
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
