#!/bin/bash

. "${DOCKER_BASE}/package/setup.sh"

component postgis   "${DOCKER_BASE}/postgis" # username password dbname
component mysql     "${DOCKER_BASE}/mysql" # password dbname
# component api       "${DOCKER_BASE}/glassfish"
# component api       "${DOCKER_BASE}/tomcat"
component api       "${DOCKER_BASE}/postgrest"
component swagger   "${DOCKER_BASE}/swagger"
component geoserver "${DOCKER_BASE}/geoserver"
component mapserver "${DOCKER_BASE}/mapserver"
component mapproxy  "${DOCKER_BASE}/mapproxy"
component mapfish   "${DOCKER_BASE}/mapfish"
component postfix   "${DOCKER_BASE}/postfix"
component cron      "${DOCKER_BASE}/cron"
component app       "${DOCKER_BASE}/serve"
component resources "${DOCKER_BASE}/serve"
component proxy     "${DOCKER_BASE}/proxy" \
	# extra1=http://container1 \
	# extra2=https://somewhere.outside.com

# component extra "${here}/../extra"

. "${DOCKER_BASE}/package/build.sh"
