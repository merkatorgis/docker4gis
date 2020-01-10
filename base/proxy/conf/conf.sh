#!/bin/sh

DOCKER_USER="${DOCKER_USER}"
API="${API}"
APP="${APP}"

RESOURCES="http://${DOCKER_USER}-resources"
GEOSERVER="http://${DOCKER_USER}-geoserver:8080/geoserver/"
MAPFISH="http://${DOCKER_USER}-mapfish:8080"
MAPSERVER="http://${DOCKER_USER}-mapserver"
MAPPROXY="http://${DOCKER_USER}-mapproxy"
SWAGGER="http://${DOCKER_USER}-swagger:8080"

echo "api=${API}
app=${APP}
static=${APP}static/
favicon.ico=${APP}favicon.ico
manifest.json=${APP}manifest.json
service-worker.js=${APP}service-worker.js
index.html=${APP}index.html
index=${APP}index
html=${APP}html/
geoserver=${GEOSERVER}
mapfish=${MAPFISH}
print=${MAPFISH}/print
resources=${RESOURCES}
mapserver=${MAPSERVER}
mapproxy=${MAPPROXY}
swagger=${SWAGGER}
swagger-ui.css=${SWAGGER}/swagger-ui.css
swagger-ui-bundle.js=${SWAGGER}/swagger-ui-bundle.js
swagger-ui-standalone-preset.js=${SWAGGER}/swagger-ui-standalone-preset.js
favicon-32x32.png=${SWAGGER}/favicon-32x32.png
favicon-16x16.png=${SWAGGER}/favicon-16x16.png
" > "/config/${DOCKER_USER}"

for proxy in ${@}
do
    echo "${proxy}" >> "/config/${DOCKER_USER}"
done
