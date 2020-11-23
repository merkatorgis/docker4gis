#!/bin/bash

find /tmp/conf/lib -name "geoserver-${GEOSERVER_VERSION}-*.zip" \
	-exec unzip -qo {} -d "${CATALINA_HOME}/webapps/geoserver/WEB-INF/lib" \;
