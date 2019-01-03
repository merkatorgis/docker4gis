FROM mdillon/postgis:10-alpine

RUN apk update; apk add --no-cache \
		openssl

COPY conf/include/gdal /tmp/gdal
RUN /tmp/gdal/install.sh
