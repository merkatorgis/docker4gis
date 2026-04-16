#!/bin/sh

DOCKER_USER=${DOCKER_USER}
HOMEDEST=${HOMEDEST}
API=${API}
APP=${APP}
AUTH_PATH=${AUTH_PATH}
CACHE_PATH=${CACHE_PATH}

RESOURCES="http://${DOCKER_USER}-resources"
GEOSERVER="http://${DOCKER_USER}-geoserver:8080/geoserver/"
MAPFISH="http://${DOCKER_USER}-mapfish:8080"
MAPSERVER="http://${DOCKER_USER}-mapserver"
MAPPROXY="http://${DOCKER_USER}-mapproxy"
SWAGGER="http://${DOCKER_USER}-swagger:8080"
OSM="http://${DOCKER_USER}-osm"

echo DOCKER_USER="${DOCKER_USER}"

conf_file=/config/$DOCKER_USER

echo "authPath=${AUTH_PATH}
cachePath=${CACHE_PATH}
homedest=${HOMEDEST}
api=${API}
app=${APP}
geoserver=${GEOSERVER}
mapfish=${MAPFISH}
resources=${RESOURCES}
mapserver=${MAPSERVER}
mapproxy=${MAPPROXY}
osm=${OSM}
qgis=${QGIS}/qgis/
qgisupload=${QGIS}/upload/
qgisfiles=${QGIS_DYNAMIC}/qgisfiles/
swagger=${SWAGGER}
swagger-ui.css.map=${SWAGGER}/swagger-ui.css.map
swagger-ui-bundle.js.map=${SWAGGER}/swagger-ui-bundle.js.map
swagger-ui-standalone-preset.js.map=${SWAGGER}/swagger-ui-standalone-preset.js.map
" >"$conf_file"

# These were to make an Elm app work, but they cause trouble when APP = e.g.
# http://host.docker.internal:3000.
[ "$APP" = "http://$DOCKER_USER-app/" ] && echo "
static=${APP}static/
favicon.ico=${APP}favicon.ico
manifest.json=${APP}manifest.json
service-worker.js=${APP}service-worker.js
index.html=${APP}index.html
index=${APP}index
html=${APP}html/
" >>"$conf_file"

for proxy in "$@"; do
    echo "${proxy}" >>"/config/${DOCKER_USER}"
done
