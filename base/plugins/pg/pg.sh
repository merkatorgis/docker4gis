#!/bin/bash

. /secrets/.pg

while ! psql -c 'SELECT PostGIS_full_version();' "${POSTGIS_URL}" > /dev/null 2>&1
do
	sleep 1
done

force="$1"
if [ "${force}" = force ]
then
	shift 1
	while ! psql "$@" "${POSTGIS_URL}" 2>/dev/null
	do
		sleep 1
	done
else
	psql "$@" "${POSTGIS_URL}"
fi
