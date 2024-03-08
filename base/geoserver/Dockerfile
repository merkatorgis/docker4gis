FROM docker4gis/tomcat:464

RUN apt update \
	&& apt install unzip

ENV GEOSERVER_EXTENSIONS='css printing pyramid' \
	GEOSERVER_USER=admin \
	GEOSERVER_PASSWORD=geoserver \
	GEOSERVER_DATA_DIR="$CATALINA_HOME/webapps/geoserver/data" \
	GEOWEBCACHE_CACHE_DIR=/geoserver/cache \
	GWC_SEED_RETRY_COUNT=10

ENV GEOSERVER_VERSION=2.24.2
# ENV GEOSERVER_VERSION=2.21.0
# ENV GEOSERVER_VERSION=2.16.0
# ENV GEOSERVER_VERSION=2.12.1

ENV GEOSERVER_DOWNLOAD_URL=https://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}

# The Tomcat image deploys the /tmp/conf/webapps/webapps
RUN mkdir -p /tmp/conf/webapps/geoserver; \
	zip=geoserver-${GEOSERVER_VERSION}-war.zip; \
	wget "${GEOSERVER_DOWNLOAD_URL}/${zip}" ;\
	unzip -qo "${zip}"; \
	unzip -qo geoserver.war -d /tmp/conf/webapps/geoserver; \
	rm -rf /tmp/conf/webapps/geoserver/data/coverages/*; \
	rm -rf /tmp/conf/webapps/geoserver/data/data/*; \
	rm -rf /tmp/conf/webapps/geoserver/data/gwc-layers/*; \
	rm -rf /tmp/conf/webapps/geoserver/data/layergroups/*; \
	rm -rf /tmp/conf/webapps/geoserver/data/workspaces/*; \
	mv /tmp/conf/geoserver/global.xml /tmp/conf/webapps/geoserver/data; \
	mv /tmp/conf/geoserver/logging.xml /tmp/conf/webapps/geoserver/data; \
	mv /tmp/conf/geoserver/logs /tmp/conf/webapps/geoserver/data

# Install any GeoServer extensions.
RUN /tmp/conf/geoserver/extensions.sh ${GEOSERVER_EXTENSIONS}
ONBUILD ARG GEOSERVER_EXTRA_EXTENSIONS
ONBUILD ENV GEOSERVER_EXTRA_EXTENSIONS=${GEOSERVER_EXTRA_EXTENSIONS}
ONBUILD RUN /tmp/conf/geoserver/extensions.sh ${GEOSERVER_EXTRA_EXTENSIONS}

RUN mkdir -p "$GEOWEBCACHE_CACHE_DIR"; \
	mv /tmp/conf/geoserver/geowebcache.xml "$GEOWEBCACHE_CACHE_DIR"

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args; \
	cp /tmp/conf/args /.docker4gis
