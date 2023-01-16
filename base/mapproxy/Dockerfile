FROM pdok/mapproxy:1.13

# WARNING - mapproxy.system - Found libproj >=5. Using this library without pyproj is deprecated and not fully supported. Please install pyproj >= 2.
# RUN pip3 install pyproj
# ERROR: Minimum supported PROJ version is 7.2.0, installed version is 5.2.0. For more information see: https://pyproj4.github.io/pyproj/stable/installation.html

COPY conf /srv/mapproxy/config

ONBUILD COPY conf /srv/mapproxy/config

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
# ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /srv/mapproxy/config/args
ONBUILD RUN cp /srv/mapproxy/config/args /.docker4gis
