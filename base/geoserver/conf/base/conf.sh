#!/bin/bash

mv /tmp/conf/base/data/* "${GEOSERVER_DATA_DIR}"/

cp ./cache/* "$GEOWEBCACHE_CACHE_DIR"
