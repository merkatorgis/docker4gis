#!/bin/sh
set -e

#cd /srv/mapproxy

if [ "$1" = 'mapproxy' ]; then  
  if [ ! -f /srv/mapproxy/mapproxy.yaml ] ;then
    mapproxy-util create -t base-config /srv/mapproxy  
  fi 
#  echo "get some  info"
#  mapproxy-util grids -l  -f /srv/mapproxy/mapproxy.yaml
#   mapproxy-util grids -g belgiumgrid --mapproxy-config mapproxy.yaml

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
