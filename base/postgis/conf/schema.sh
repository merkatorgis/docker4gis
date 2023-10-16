#!/bin/bash
# set -x

scripts_dir=$1
export SCHEMA=${2:-$(basename "$scripts_dir")}

pushd "$scripts_dir" || exit 1

# The optional 0-script should always be run.
[ -x 0.sh ] && {
	# If it exists, it should complete successfully.
	./0.sh || exit 1
}

# Test if versioning function exists.
function=$SCHEMA.__version
if pg.sh -c "select '$function'::regproc" >/dev/null 2>&1; then
	# Read the current version from the database.
	version=$(pg.sh -Atc "select $function()") || exit 1
else
	version=0
	# Create the schema.
	pg.sh -c "create schema if not exists $SCHEMA"
	[ "$SCHEMA" != mail ] && [ "$SCHEMA" != web ] && [ "$SCHEMA" != admin ] && pg.sh -c "
		grant usage on schema $SCHEMA
		to web_anon
		, web_passwd
		, web_user
		, web_admin
	"
fi

proceed() {
	# Increment version.
	version=$((version + 1))
	script=./"$version".sh
	# If a script to create the new version exists, execute it.
	[ -x "$script" ] &&
		"$script"
}

while proceed; do
	# A script for the next version existed, and was executed successfully. Now,
	# ensure the database knows its current version.
	pg.sh -c "
		CREATE OR REPLACE FUNCTION $function()
		RETURNS integer
		LANGUAGE sql AS \$function\$
			-- Returns the version number of this schema's data model,
			-- for the migration scripts to know where they should start.
		    SELECT $version;
		\$function\$;
	"
done

popd || exit 1
