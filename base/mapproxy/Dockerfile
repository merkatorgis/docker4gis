FROM pdok/mapproxy

COPY conf /srv/mapproxy/config

ONBUILD COPY conf /srv/mapproxy/config

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
# ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /srv/mapproxy/config/args; \
    cp /srv/mapproxy/config/args /.docker4gis
