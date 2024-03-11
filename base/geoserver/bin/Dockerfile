FROM alpine:3.19.1

ARG GEOSERVER_VERSION
ARG GEOSERVER_EXTENSIONS

ENV GEOSERVER_BIN=/geoserver/bin
RUN mkdir -p ${GEOSERVER_BIN}
WORKDIR ${GEOSERVER_BIN}

ENV GEOSERVER_DOWNLOAD_URL=https://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}

RUN zip=geoserver-${GEOSERVER_VERSION}-war.zip; \
    wget "$GEOSERVER_DOWNLOAD_URL/$zip"

RUN for extension in ${GEOSERVER_EXTENSIONS}; do \
    zip=geoserver-${GEOSERVER_VERSION}-$extension-plugin.zip; \
    wget -O "$zip" "$GEOSERVER_DOWNLOAD_URL/extensions/$zip/download"; \
    done
