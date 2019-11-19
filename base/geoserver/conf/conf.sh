#!/bin/bash

SCRIPT="$1"

if [ "$SCRIPT" ]; then
	DIR="$PWD"
	cd $(dirname "$SCRIPT")
	"$SCRIPT"
	cd "$DIR"
else
	cp -r /tmp/conf/certificates/ /
	mkdir -p     /tmp/conf/lib
	        find /tmp/conf/lib -name "geoserver-${GEOSERVER_VERSION}-*.zip" -exec unzip -qo {} -d $CATALINA_HOME/webapps/geoserver/WEB-INF/lib/ \;
	find $(dirname "$0") -name 'conf.sh' -mindepth 2 -exec "$0" {} \;
fi
