# Demo service

The demo service (listing all configured capabilities), doesn't run through
the reversed proxy (yet). Therefore, the default package will publish mapproxy
on port 58081, so the url is: http://localhost:58081/demo

# Reversed proxy

When used with the docker4gis/proxy component, the "real" services are
reachable through https://localhost.merkator.com:7443/mapproxy, e.g.

- https://localhost.merkator.com:7443/mapproxy/wmts/1.0.0/WMTSCapabilities.xml
- https://localhost.merkator.com:7443/mapproxy/wmts/osm/GLOBAL_MERCATOR/15/16979/10643.png
