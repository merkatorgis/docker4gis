FROM tomcat:9.0.2-alpine

RUN apk update; apk add --no-cache \
	curl wget unzip grep sed \
	postgresql-client \
	ttf-freefont

ENV GEOSERVER_USER=admin \
	GEOSERVER_PASSWORD=geoserver \
	GEOSERVER_DATA_DIR=/geoserver/data \
	GEOWEBCACHE_CACHE_DIR=/geoserver/cache \
	GWC_SEED_RETRY_COUNT=10 \
	PATH=/util:$PATH \
	JAVA_OPTS='-Xms2g -Xmx2g -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:+UseParNewGC -XX:NewRatio=2 -XX:+AggressiveOpts'

ADD conf /tmp/conf

RUN mv /tmp/conf/base/conf/server.xml $CATALINA_HOME/conf/server.xml; \
    mv /tmp/conf/base/conf/web.xml    $CATALINA_HOME/conf/web.xml; \
	mkdir -p /usr/local/tomcat/webapps/geoserver; \
	unzip -qo /tmp/conf/base/geoserver/geoserver-*-war.zip -d /tmp/conf/base; \
	unzip -qo /tmp/conf/base/geoserver.war                 -d $CATALINA_HOME/webapps/geoserver; \
	unzip -qo /tmp/conf/base/geoserver/lib/*.zip           -d $CATALINA_HOME/webapps/geoserver/WEB-INF/lib/; \ 
	mv /tmp/conf/base/geoserver/lib/*.jar                     $CATALINA_HOME/webapps/geoserver/WEB-INF/lib/; \
	mv /tmp/conf/base/entrypoint/* /; \
	/tmp/conf/plugins/pg/install.sh

ADD conf/base/jai/* /jai/
RUN mv /jai/jai-1_1_3/lib/*.jar       $JAVA_HOME/lib/ext/; \
	mv /jai/jai-1_1_3/lib/*.so        $JAVA_HOME/lib/amd64/; \
	mv /jai/jai_imageio-1_1/lib/*.jar $JAVA_HOME/lib/ext/; \
	mv /jai/jai_imageio-1_1/lib/*.so  $JAVA_HOME/lib/amd64/; \
	rm $CATALINA_HOME/webapps/geoserver/WEB-INF/lib/jai_*.jar; \
	rm -rf /jai

ENTRYPOINT ["/entrypoint"]
CMD ["geoserver"]

ONBUILD ADD conf /tmp/conf
