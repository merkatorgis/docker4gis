ARG GEOSERVER_VERSION

FROM docker.merkator.com/geoserver/bin:$GEOSERVER_VERSION as bin

FROM docker4gis/tomcat:467

RUN apt update \
	&& apt install unzip

ARG GEOSERVER_VERSION
ARG GEOSERVER_EXTENSIONS

ENV GEOSERVER_VERSION=${GEOSERVER_VERSION} \
	GEOSERVER_EXTENSIONS=${GEOSERVER_EXTENSIONS} \
	GEOSERVER_BIN=/geoserver/bin \
	GEOSERVER_USER=admin \
	GEOSERVER_PASSWORD=geoserver \
	GEOSERVER_DATA_DIR=${CATALINA_HOME}/webapps/geoserver/data \
	GEOWEBCACHE_CACHE_DIR=/geoserver/cache \
	GWC_SEED_RETRY_COUNT=10

COPY --from=bin ${GEOSERVER_BIN} ${GEOSERVER_BIN}

# The Tomcat image deploys the /tmp/conf/webapps/webapps
RUN webapp=/tmp/conf/webapps/geoserver; \
	mkdir -p "$webapp"; \
	zip=${GEOSERVER_BIN}/geoserver-${GEOSERVER_VERSION}-war.zip; \
	unzip -o "$zip" -d "$GEOSERVER_BIN"; \
	unzip -o "$GEOSERVER_BIN/geoserver.war" -d "$webapp"; \
	data=${webapp}/data; \
	rm -rf "$data/coverages"/*; \
	rm -rf "$data/data"/*; \
	rm -rf "$data/gwc-layers"/*; \
	rm -rf "$data/layergroups"/*; \
	rm -rf "$data/workspaces"/*; \
	mv /tmp/conf/geoserver/global.xml "$data"; \
	mv /tmp/conf/geoserver/logging.xml "$data"; \
	mv /tmp/conf/geoserver/logs "$data"

# Install any GeoServer extensions.
ONBUILD ARG GEOSERVER_EXTRA_EXTENSIONS
ONBUILD ENV GEOSERVER_EXTRA_EXTENSIONS=${GEOSERVER_EXTRA_EXTENSIONS}
ONBUILD RUN /tmp/conf/geoserver/extensions.sh

RUN mkdir -p "$GEOWEBCACHE_CACHE_DIR"; \
	mv /tmp/conf/geoserver/geowebcache.xml "$GEOWEBCACHE_CACHE_DIR"

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args; \
	cp /tmp/conf/args /.docker4gis
