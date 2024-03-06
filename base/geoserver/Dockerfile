FROM docker4gis/tomcat:460

ENV GEOSERVER_USER=admin \
	GEOSERVER_PASSWORD=geoserver \
	GEOSERVER_DATA_DIR="$CATALINA_HOME/webapps/geoserver/data" \
	GEOWEBCACHE_CACHE_DIR=/geoserver/cache \
	GWC_SEED_RETRY_COUNT=10

ENV GEOSERVER_VERSION=2.21.0
# ENV GEOSERVER_VERSION=2.16.0
# ENV GEOSERVER_VERSION=2.12.1

# The Tomcat image deploys the /tmp/conf/webapps/webapps
RUN mkdir -p /tmp/conf/webapps/geoserver; \
	unzip -qo /tmp/conf/geoserver/dist/geoserver-"$GEOSERVER_VERSION"-war.zip -d /tmp/conf/geoserver/dist; \
	unzip -qo /tmp/conf/geoserver/dist/geoserver.war -d /tmp/conf/webapps/geoserver; \
	rm -rf /tmp/conf/webapps/geoserver/data/coverages/*; \
	rm -rf /tmp/conf/webapps/geoserver/data/data/*; \
	rm -rf /tmp/conf/webapps/geoserver/data/gwc-layers/*; \
	rm -rf /tmp/conf/webapps/geoserver/data/layergroups/*; \
	rm -rf /tmp/conf/webapps/geoserver/data/workspaces/*; \
	mv /tmp/conf/geoserver/global.xml /tmp/conf/webapps/geoserver/data; \
	mv /tmp/conf/geoserver/logging.xml /tmp/conf/webapps/geoserver/data; \
	mv /tmp/conf/geoserver/logs /tmp/conf/webapps/geoserver/data

RUN mkdir -p "$GEOWEBCACHE_CACHE_DIR"; \
	mv /tmp/conf/geoserver/geowebcache.xml "$GEOWEBCACHE_CACHE_DIR"

# The ADD command takes care of unzip & tar
ADD conf/geoserver/jai/* /tmp/conf/geoserver/jai/
RUN rm /tmp/conf/webapps/geoserver/WEB-INF/lib/jai_*.jar; \
	mv /tmp/conf/geoserver/jai/jai-1_1_3/lib/*.jar       $JAVA_HOME/lib/ext/; \
	mv /tmp/conf/geoserver/jai/jai-1_1_3/lib/*.so        $JAVA_HOME/lib/amd64/; \
	mv /tmp/conf/geoserver/jai/jai_imageio-1_1/lib/*.jar $JAVA_HOME/lib/ext/; \
	mv /tmp/conf/geoserver/jai/jai_imageio-1_1/lib/*.so  $JAVA_HOME/lib/amd64/

COPY conf/.docker4gis /.docker4gis
COPY build.sh /.docker4gis/build.sh
COPY run.sh /.docker4gis/run.sh
ONBUILD COPY conf /tmp/conf
ONBUILD RUN touch /tmp/conf/args; \
	cp /tmp/conf/args /.docker4gis
