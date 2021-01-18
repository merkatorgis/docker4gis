#!/bin/sh

DOCKER_USER=${DOCKER_USER}
SECRET=${SECRET}
HOMEDEST=${HOMEDEST}
API=${API}
APP=${APP}
AUTH_PATH=${AUTH_PATH}

RESOURCES="http://${DOCKER_USER}-resources"
GEOSERVER="http://${DOCKER_USER}-geoserver:8080/geoserver/"
MAPFISH="http://${DOCKER_USER}-mapfish:8080"
MAPSERVER="http://${DOCKER_USER}-mapserver"
MAPPROXY="http://${DOCKER_USER}-mapproxy"
SWAGGER="http://${DOCKER_USER}-swagger:8080"
OSM="http://${DOCKER_USER}-osm"

echo DOCKER_USER="${DOCKER_USER}"

echo "authPath=${AUTH_PATH}
secret=${SECRET}
homedest=${HOMEDEST}
api=${API}
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
resources=${RESOURCES}
mapserver=${MAPSERVER}
mapproxy=${MAPPROXY}
osm=${OSM}
swagger=${SWAGGER}
swagger-ui.css.map=${SWAGGER}/swagger-ui.css.map
swagger-ui-bundle.js.map=${SWAGGER}/swagger-ui-bundle.js.map
swagger-ui-standalone-preset.js.map=${SWAGGER}/swagger-ui-standalone-preset.js.map
" >"/config/${DOCKER_USER}"

for proxy in ${@}; do
    echo "${proxy}" >>"/config/${DOCKER_USER}"
done
