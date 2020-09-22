FROM alpine:3.12

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh

ONBUILD COPY conf/run.sh /.docker4gis/run.sh
