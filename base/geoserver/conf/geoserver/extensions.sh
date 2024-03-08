#!/bin/bash

extensions=$*

for extension in $extensions; do
    zip=geoserver-$GEOSERVER_VERSION-$extension-plugin.zip
    wget -O "$zip" "$GEOSERVER_DOWNLOAD_URL/extensions/$zip/download"
    unzip -qo "$zip" -d /tmp/conf/webapps/geoserver/WEB-INF/lib
done
