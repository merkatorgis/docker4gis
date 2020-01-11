FROM camptocamp/mapfish_print

ADD conf /tmp/conf

RUN mv /tmp/conf/print-apps ${CATALINA_HOME}/webapps/ROOT/print-apps/; \
    mv /tmp/conf/fonts ${CATALINA_HOME}/webapps/ROOT/WEB-INF/classes/fonts/; \
    mv /tmp/conf/mapfish-spring-custom-fonts.xml ${CATALINA_HOME}/webapps/ROOT/WEB-INF/classes/mapfish-spring-custom-fonts.xml

ENV CATALINA_OPTS='-DprintTimeout=1799' \
	JAVA_OPTS='-Xms2g -Xmx2g -XX:SoftRefLRUPolicyMSPerMB=36000 -XX:+UseParNewGC -XX:NewRatio=2 -XX:+AggressiveOpts'

ONBUILD ADD conf /tmp/conf
