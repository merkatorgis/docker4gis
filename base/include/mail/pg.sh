#!/bin/bash

if [ "$POSTGIS_ENV_POSTGIS_VERSION" ]; then
	POSTGIS_URL="postgresql://$POSTGIS_ENV_POSTGRES_USER:$POSTGIS_ENV_POSTGRES_PASSWORD@$POSTGIS_PORT_5432_TCP_ADDR:$POSTGIS_PORT_5432_TCP_PORT/$POSTGIS_ENV_POSTGRES_DB"
else
	POSTGIS_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@$HOSTNAME/${POSTGRES_DB}"
fi

while true
do
	psql -c 'SELECT PostGIS_full_version();' "$POSTGIS_URL" 1>/dev/null 2>&1
	if [ "$?" = '0' ]; then
		break
	fi
	# echo "Waiting for PostGIS@$POSTGRES_DB"...
	sleep 1
done

psql "$@" "$POSTGIS_URL"
