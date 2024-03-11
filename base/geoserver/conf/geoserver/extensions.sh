#!/bin/bash

GEOSERVER_DOWNLOAD_URL=https://sourceforge.net/projects/geoserver/files/GeoServer/$GEOSERVER_VERSION

for extension in $GEOSERVER_EXTENSIONS $GEOSERVER_EXTRA_EXTENSIONS; do
    zip=geoserver-$GEOSERVER_VERSION-$extension-plugin.zip
    file=$GEOSERVER_BIN/$zip
    [ -f "$file" ] || wget -O "$file" "$GEOSERVER_DOWNLOAD_URL/extensions/$zip/download"
    unzip -o "$file" -d /tmp/conf/webapps/geoserver/WEB-INF/lib
done
