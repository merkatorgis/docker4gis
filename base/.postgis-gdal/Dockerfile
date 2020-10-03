FROM mdillon/postgis:11-alpine

RUN apk update; apk add --no-cache \
		openssl

COPY gdal/setup.sh /tmp/gdal/setup.sh
RUN /tmp/gdal/setup.sh


ENV LIBKML_VERSION 1.3.0

COPY gdal/libkml.sh /tmp/gdal/libkml.sh
RUN /tmp/gdal/libkml.sh


ENV PROJ_VERSION 6.2.0
ENV PROJ_DATUMGRID_VERSION 1.8

COPY gdal/proj.sh /tmp/gdal/proj.sh
RUN /tmp/gdal/proj.sh


ENV GDAL_VERSION 3.0.1

COPY gdal/gdal.sh /tmp/gdal/gdal.sh
RUN /tmp/gdal/gdal.sh


COPY gdal/teardown.sh /tmp/gdal/teardown.sh
RUN /tmp/gdal/teardown.sh
