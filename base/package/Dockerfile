FROM alpine:3.12

COPY conf/utils /.docker4gis
COPY build.sh /.docker4gis/build.sh

ONBUILD COPY conf/run.sh /.docker4gis/run.sh
