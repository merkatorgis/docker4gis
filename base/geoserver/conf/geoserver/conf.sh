#!/bin/bash

cp -r dynamic "${GEOSERVER_DATA_DIR}/workspaces"

find "${GEOSERVER_DATA_DIR}" -name 'datastore.xml' \
	-exec ./datastore.sh {} \;

find /tmp/conf/lib -name "geoserver-${GEOSERVER_VERSION}-*.zip" \
	-exec unzip -qo {} -d "${CATALINA_HOME}/webapps/geoserver/WEB-INF/lib" \;
