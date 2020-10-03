FROM pdok/mapserver:latest

ONBUILD COPY conf /srv/data

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
# ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /srv/data/args; \
    cp /srv/data/args /.docker4gis
