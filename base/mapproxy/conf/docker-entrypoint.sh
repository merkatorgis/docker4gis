#!/bin/sh
set -e

#cd /srv/mapproxy

if [ "$1" = 'mapproxy' ]; then  
  if [ ! -f /srv/mapproxy/mapproxy.yaml ] ;then
    mapproxy-util create -t base-config /srv/mapproxy  
  fi 

  mkdir -p /srv/mapproxy/cache
  mkdir -p /srv/mapproxy/cache/locks
  mkdir -p /srv/mapproxy/cache/tile_locks

  echo "Start mapproxy"
  if [ -f /srv/mapproxy/newmapproxy.yaml ]; then
    cp -v  -rf /srv/mapproxy/newmapproxy.yaml /srv/mapproxy/mapproxy.yaml
  fi
  if [ -f /srv/mapproxy/newseed.yaml ]; then
    cp -v  -rf /srv/mapproxy/newseed.yaml /srv/mapproxy/seed.yaml
  fi  
  mapproxy-seed -f /srv/mapproxy/mapproxy.yaml -s /srv/mapproxy/seed.yaml --summary --seed ALL
  mapproxy-util serve-develop /srv/mapproxy/mapproxy.yaml  -b 0.0.0.0:8080    
fi
