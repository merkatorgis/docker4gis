#!/bin/bash

DATASTORE_XML="$1"

inject ()
{
	local key="$1"; local val="$2"
	sed -i -e "s~<entry key=\"$key\">[^<]*</entry>~<entry key=\"$key\">$val</entry>~" "$DATASTORE_XML"
}

. /secrets/.pg

inject 'user'     "$POSTGIS_USER"
inject 'passwd'   "$POSTGIS_PASSWORD"
inject 'host'     "$POSTGIS_ADDRESS"
inject 'port'     '5432'
inject 'database' "$POSTGIS_DB"
