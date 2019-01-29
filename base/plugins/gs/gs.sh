#!/bin/bash

COMPONENT="$2" # gwc -> /geoserver/gwc/rest

URL="https://${GEOSERVER_CONTAINER}/geoserver"
if [ "$COMPONENT" ]; then URL="$URL/$COMPONENT"; fi
URL="$URL/rest"

CURL='curl -ksSw %{http_code}-%{time_total}-%{url_effective}\n -o /dev/null'
CURL="$CURL -u $GEOSERVER_USER:$GEOSERVER_PASSWORD"

GET="wget -qO - --no-check-certificate --http-user=${GEOSERVER_USER} --http-password=${GEOSERVER_PASSWORD}"

if [ "$1" == "GET" ]; then
	echo "$GET $URL"
elif [ "$1" == "POST_STYLE" ]; then
	echo "$CURL -X POST -H Content-Type:application/vnd.ogc.sld+xml $URL"
else # PUT, POST, or DELETE
	echo "$CURL -X $1 -H Content-Type:text/xml $URL"
fi
